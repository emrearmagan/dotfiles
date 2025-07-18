#!/bin/bash
#
# Ansible playbook tester.
# Based on geerlingguy's Ansible role tester.
#
# Usage: [OPTIONS] .tests/test.sh
# Example: test_idempotence=false ./test.sh     # Skip idempotence check
#
#   - distro: a supported Docker distro version (default = "ubuntu1604")
#   - playbook: a playbook in the tests directory (default = "test.yml")
#   - cleanup: whether to remove the Docker container (default = true)
#   - container_id: the --name to set for the container (default = timestamp)
#   - test_idempotence: whether to test playbook's idempotence (default = true)
# 
# See: https://github.com/davestephens/ansible-dotfiles/blob/master/tests/test.sh

# Exit on any individual command failure.
set -e

# Color output
green='\033[0;32m'
red='\033[0;31m'
neutral='\033[0m'

# Allow environment variables to override defaults.
distro="${distro:-ubuntu2004}"
docker_image="geerlingguy/docker-${distro}-ansible"
playbook="${playbook:-playbook.yml}"
container_id="${container_id:-ansible-test-$(date +%s)}"
test_idempotence="${test_idempotence:-true}"
cleanup="${cleanup:-true}"
## Mount the whole project including the ../config
project_dir="$(cd "$(dirname "$0")/../.." && pwd)"
playbook_path="/playground/ansible/${playbook}"
skip_tags="ruby,package,brew,fonts"

echo $project_dir

# Always cleanup the container when the script exits
cleanup_container() {
  if [[ "${cleanup}" == "true" ]]; then
    echo -e "${green}\nCleaning up container: ${container_id}${neutral}"
    docker rm -f "${container_id}" >/dev/null 2>&1 || true
  fi
}
trap cleanup_container EXIT

# Start Docker container with Ansible preinstalled
echo -e "${green}Starting Docker container: ${docker_image}${neutral}"
docker pull "${docker_image}:latest"
docker run --detach \
  --name "${container_id}" \
  --volume="${project_dir}:/playground:rw" \
  --privileged \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
  "${docker_image}:latest" \
  /lib/systemd/systemd

# Show Ansible version
echo -e "${green}\nChecking Ansible version${neutral}"
docker exec -t "${container_id}" ansible-playbook --version

# Install Galaxy roles if needed
if [[ -f "${project_dir}/requirements.yml" ]]; then
  echo -e "${green}\nInstalling Ansible Galaxy dependencies${neutral}"
  docker exec -t "${container_id}" ansible-galaxy install -r "${playbook_path%/*}/requirements.yml"
fi

# Syntax check
echo -e "${green}\nChecking syntax: ${playbook}${neutral}"
docker exec -t "${container_id}" ansible-playbook "${playbook_path}" --syntax-check

# Run playbook once
echo -e "${green}\nRunning playbook${neutral}"
docker exec -e ANSIBLE_FORCE_COLOR=1 -t "${container_id}" ansible-playbook "${playbook_path}" --skip-tags "${skip_tags}"

# Run idempotence test (optional second run)
if [[ "${test_idempotence}" == "true" ]]; then
  echo -e "${green}\nRunning idempotence test...${neutral}"
  result=$(docker exec "${container_id}" ansible-playbook "${playbook_path}" --skip-tags "${skip_tags}")
  echo "${result}"

  echo "${result}" | grep -q 'changed=0.*failed=0' \
    && echo -e "${green}Idempotence test: pass ✅${neutral}" \
    || { echo -e "${red}Idempotence test: FAIL ❌${neutral}"; exit 1; }
fi
