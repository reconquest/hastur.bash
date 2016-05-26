_base_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source $_base_dir/vendor/github.com/reconquest/sudo.bash/sudo.bash

# FIXME make it possible to specify non-system root dir
export _hastur_root_dir=${_hastur_root_dir:-/var/lib/hastur}

export _hastur_packages=${_hastur_packages:-bash,coreutils,shadow}

hastur() {
    sudo hastur -q -r $_hastur_root_dir "${@}"
}

hastur:keep-containers() {
    hastur:destroy-containers() {
        printf "containers are kept in $_hastur_root_dir... "
    }

    hastur:destroy-root() {
        :
    }
}

hastur:keep-images() {
    hastur:destroy-root() {
        printf "root is kept in $_hastur_root_dir... "
    }
}

hastur:get-packages() {
    printf $_hastur_packages
}

hastur:init() {
    local packages="$1"

    printf "[hastur] cheking and initializing hastur... "

    sudo mkdir -p $_hastur_root_dir

    _hastur_packages="$_hastur_packages,$packages"

    local hastur_out

    if hastur_out=$(
        hastur -p $_hastur_packages -S /usr/bin/true 2>&1 | tee /dev/stderr
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

    hastur -Q "$container_name" --ip 2>/dev/null >/dev/null
}

hastur:list() {
    sudo:silent hastur -Qc | awk '{ print $1 }'
}


hastur:print-ip() {
    local container_name="$1"

    sudo:silent hastur -Q "$container_name" --ip | cut -f1 -d/
}

hastur:print-rootfs() {
    local container_name="$1"

    sudo:silent hastur -Q "$container_name" --rootfs
}
