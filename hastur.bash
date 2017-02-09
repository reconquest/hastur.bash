if ! declare -f import:use &>/dev/null; then
    _base_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
    source $_base_dir/vendor/github.com/reconquest/import.bash/import.bash
fi

import:use "github.com/reconquest/sudo.bash"

# FIXME make it possible to specify non-system root dir
export _hastur_root_dir=${_hastur_root_dir:-/var/lib/hastur}
export _hastur_bridge=${_hastur_bridge:-"br0:10.0.0.1/8"}
export _hastur_packages=${_hastur_packages:-bash,coreutils,shadow}

hastur() {
    sudo hastur -b $_hastur_bridge -q -r $_hastur_root_dir "${@}"
}

hastur:keep-images() {
    hastur:destroy-root() {
        printf "root is kept in $_hastur_root_dir... "
    }
}

hastur:get-packages() {
    printf $_hastur_packages
}

hastur:set-bridge() {
    _hastur_bridge="$1"
}

hastur:init() {
    local packages="$1"

    printf "[hastur] checking and initializing hastur... "

    sudo mkdir -p $_hastur_root_dir

    _hastur_packages="$_hastur_packages,$packages"

    local hastur_out

    if hastur_out=$(
        hastur -p "$_hastur_packages" -S /usr/bin/true 2>&1 | tee /dev/stderr
    )
    then
        printf "ok.\n"
    else
        printf "fail.\n\n%s\n" "$hastur_out"
        return 1
    fi
}

hastur:spawn() {
    hastur -p $(hastur:get-packages) -kS "${@}"
}

hastur:run() {
    local container_name="$1"
    shift

    hastur:spawn -n "$container_name" "${@}"
}

hastur:destroy() {
    local container_name="$1"

    hastur -f -D "$container_name"
}

hastur:destroy-root() {
    hastur --free
}

hastur:cleanup() {
    printf "Cleaning up hastur containers...\n"

    hastur:destroy-root

    printf "ok.\n"
}

hastur:is-active() {
    local container_name="$1"
    shift

    grep -vq 'inactive' <(hastur -Q "$container_name")
}

hastur:list() {
    sudo:silent hastur -Q | awk '{ print $1 }'
}

hastur:print-ip() {
    local container_name="$1"

    sudo:silent hastur -Q "$container_name" | awk '{print $3}' | cut -f1 -d/
}

hastur:print-rootfs() {
    local container_name="$1"

    sudo:silent hastur -Q "$container_name" | awk '{print $4}'
}
