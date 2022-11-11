#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

################################################################
# Migrate existing folder to a new partition
#
# Globals:
#   None
# Arguments:
#   1 - the path of the disk or partition
#   2 - the folder path to migration
#   3 - the mount options to use.
# Outputs:
#   None
################################################################
migrate_and_mount_disk() {
    local device_name=$1
    local folder_path=$2
    local mount_options=$3
    local temp_path="/mnt${folder_path}"
    local old_path="${folder_path}-old"

    # AWS EC2 API Block Device Mapping name to Linux NVME device name
    disk_name="/dev/$(readlink "$device_name")"

    # partition the disk (single data partition)
    parted -a optimal -s $disk_name \
        mklabel gpt \
        mkpart data xfs 0% 90%

    # wait for the disk to settle
    sleep 5

    # install an xfs filesystem to the disk
    mkfs -t xfs "${disk_name}p1"

    # check if the folder already exists
    if [ -d "${folder_path}" ]; then
        FILE=$(ls -A ${folder_path})
        >&2 echo $FILE
        mkdir -p ${temp_path}
        mount "${disk_name}p1" ${temp_path}
        # Empty folder give error on /*
        if [ ! -z "$FILE" ]; then
            cp -Rax ${folder_path}/* ${temp_path}
        fi
    fi

    # create the folder
    mkdir -p ${folder_path}

    # add the mount point to fstab and mount the disk
    echo "UUID=$(blkid -s UUID -o value "${disk_name}p1") ${folder_path} xfs ${mount_options} 0 1" >> /etc/fstab
    mount -a

    # if selinux is enabled restore the objects on it
    if selinuxenabled; then
        restorecon -R ${folder_path}
    fi
}

# migrate and mount the existing folders to dedicated EBS Volumes
migrate_and_mount_disk "/dev/sdf" "/home"           defaults,nofail,nodev,nosuid
migrate_and_mount_disk "/dev/sdg" "/var"            defaults,nofail,nodev
migrate_and_mount_disk "/dev/sdh" "/var/log"        defaults,nofail,nodev,nosuid
migrate_and_mount_disk "/dev/sdi" "/var/log/audit"  defaults,nofail,nodev,nosuid
migrate_and_mount_disk "/dev/sdj" "/var/lib/docker" defaults,nofail

# Resize on instance launch
cloud_init_script="/var/lib/cloud/scripts/per-boot/resize-disks.sh"
cat > "$cloud_init_script" <<EOF
#!/usr/bin/env bash

set -x

lsblk

growpart "/dev/\$(readlink "/dev/sdf")" 1; xfs_growfs '/home'
growpart "/dev/\$(readlink "/dev/sdg")" 1; xfs_growfs '/var'
growpart "/dev/\$(readlink "/dev/sdh")" 1; xfs_growfs '/var/log'
growpart "/dev/\$(readlink "/dev/sdi")" 1; xfs_growfs '/var/log/audit'
growpart "/dev/\$(readlink "/dev/sdj")" 1; xfs_growfs '/var/lib/docker'

df -Th | grep -E 'Filesystem|xfs'
EOF
chmod +x "$cloud_init_script"
