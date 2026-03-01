#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FACTORY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MAIN_ROOT="${MAIN_REPOS_ROOT:-/home/sung2287/projects}"
IMPORTED_ROOT="${IMPORTED_ROOT:-${FACTORY_ROOT}/imported}"

print_list() {
  local -n _items=$1
  for item in "${_items[@]}"; do
    echo "  - ${item}"
  done
}

select_from_list() {
  local out_var="$1"
  shift
  local prompt="$1"
  shift
  local options=("$@")
  local selected=""

  PS3="${prompt} "
  select opt in "${options[@]}" "Quit"; do
    if [[ "${opt:-}" == "Quit" ]]; then
      echo "Cancelled."
      exit 0
    fi
    if [[ -n "${opt:-}" ]]; then
      selected="${opt}"
      break
    fi
    echo "Invalid selection. Try again."
  done

  printf -v "${out_var}" '%s' "${selected}"
}

pick_first_by_prefix() {
  local dir="$1"
  local prefix="$2"
  local suffix="$3"
  local path=""
  local name=""
  local rest=""

  while IFS= read -r path; do
    name="$(basename "${path}")"
    rest="${name#${prefix}}"
    if [[ "${rest}" == "${name}" || -z "${rest}" ]]; then
      continue
    fi
    if [[ "${rest}" =~ ^[0-9] ]]; then
      continue
    fi
    echo "${path}"
    return 0
  done < <(find "${dir}" -mindepth 1 -maxdepth 1 -type f -name "${prefix}*${suffix}" 2>/dev/null | sort)

  return 1
}

is_allowed_pull_path() {
  local rel="$1"
  case "${rel}" in
    docs/prd/*|docs/contract/*|docs/adr/*|docs/concepts/*|docs/platform/*|docs/governance/*|docs/repomap/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_selected_prd_path() {
  local rel="$1"
  local prd_no="$2"
  local name

  case "${rel}" in
    docs/governance/*|docs/repomap/*)
      return 0
      ;;
    docs/prd/*)
      name="$(basename "${rel}")"
      [[ "${name}" =~ ^PRD-${prd_no}_.+\.md$ ]]
      return
      ;;
    docs/contract/specs/*)
      name="$(basename "${rel}")"
      [[ "${name}" =~ ^B-${prd_no}[^0-9].*\.contract\.md$ ]]
      return
      ;;
    docs/contract/intent_maps/*)
      name="$(basename "${rel}")"
      [[ "${name}" =~ ^C-${prd_no}[^0-9].*\.intent_map\.md$ ]]
      return
      ;;
    docs/platform/*)
      name="$(basename "${rel}")"
      [[ "${name}" =~ ^D-${prd_no}[^0-9].*\.platform\.md$ ]]
      return
      ;;
    docs/adr/*)
      name="$(basename "${rel}")"
      [[ "${name}" =~ ^ADR-${prd_no}_.+\.md$ ]]
      return
      ;;
    docs/concepts/*)
      [[ "${rel}" == *"PRD-${prd_no}"* ]]
      return
      ;;
    *)
      return 1
      ;;
  esac
}

run_push() {
  local project="$1"
  local prd_file="$2"
  local prd_num="$3"
  local factory_project_root="$4"
  local main_project_root="$5"

  local src_prd="${factory_project_root}/docs/prd/${prd_file}"
  local src_b src_c src_d src_adr

  src_b="$(pick_first_by_prefix "${factory_project_root}/docs/contract/specs" "B-${prd_num}" ".contract.md" || true)"
  src_c="$(pick_first_by_prefix "${factory_project_root}/docs/contract/intent_maps" "C-${prd_num}" ".intent_map.md" || true)"
  src_d="$(pick_first_by_prefix "${factory_project_root}/docs/platform" "D-${prd_num}" ".platform.md" || true)"
  src_adr="$(pick_first_by_prefix "${factory_project_root}/docs/adr" "ADR-${prd_num}_" ".md" || true)"

  if [[ ! -f "${src_prd}" ]]; then
    echo "Abort: Missing source PRD in factory canonical: ${src_prd}"
    exit 1
  fi

  if [[ -z "${src_b}" ]]; then
    echo "WARN: Missing B-${prd_num} (optional)"
  fi
  if [[ -z "${src_c}" ]]; then
    echo "WARN: Missing C-${prd_num} (optional)"
  fi
  if [[ -z "${src_d}" ]]; then
    echo "WARN: Missing D-${prd_num} (optional)"
  fi
  if [[ -z "${src_adr}" ]]; then
    echo "INFO: Missing ADR-${prd_num} (optional)"
  fi

  local copied=()
  local archived=()

  local dst_prd="${main_project_root}/docs/prd/$(basename "${src_prd}")"
  mkdir -p "$(dirname "${dst_prd}")"
  cp -f "${src_prd}" "${dst_prd}"
  copied+=("${dst_prd}")

  local dst_b=""
  local dst_c=""
  local dst_d=""
  local dst_adr=""

  if [[ -n "${src_b}" ]]; then
    dst_b="${main_project_root}/docs/contract/specs/$(basename "${src_b}")"
    mkdir -p "$(dirname "${dst_b}")"
    cp -f "${src_b}" "${dst_b}"
    copied+=("${dst_b}")
  fi

  if [[ -n "${src_c}" ]]; then
    dst_c="${main_project_root}/docs/contract/intent_maps/$(basename "${src_c}")"
    mkdir -p "$(dirname "${dst_c}")"
    cp -f "${src_c}" "${dst_c}"
    copied+=("${dst_c}")
  fi

  if [[ -n "${src_d}" ]]; then
    dst_d="${main_project_root}/docs/platform/$(basename "${src_d}")"
    mkdir -p "$(dirname "${dst_d}")"
    cp -f "${src_d}" "${dst_d}"
    copied+=("${dst_d}")
  fi

  if [[ -n "${src_adr}" ]]; then
    dst_adr="${main_project_root}/docs/adr/$(basename "${src_adr}")"
    mkdir -p "$(dirname "${dst_adr}")"
    cp -f "${src_adr}" "${dst_adr}"
    copied+=("${dst_adr}")
  fi

  if ! command -v rsync >/dev/null 2>&1; then
    echo "ERROR: rsync is required for PUSH governance/repomap mirror."
    exit 1
  fi

  local gov_src="${factory_project_root}/docs/governance"
  local repomap_src="${factory_project_root}/docs/repomap"
  local gov_dst="${main_project_root}/docs/governance"
  local repomap_dst="${main_project_root}/docs/repomap"

  if [[ -d "${gov_src}" ]]; then
    mkdir -p "${gov_dst}"
    rsync -a --delete "${gov_src}/" "${gov_dst}/"
    copied+=("${gov_dst}/ (mirrored)")
  fi

  if [[ -d "${repomap_src}" ]]; then
    mkdir -p "${repomap_dst}"
    rsync -a --delete "${repomap_src}/" "${repomap_dst}/"
    copied+=("${repomap_dst}/ (mirrored)")
  fi

  # After PUSH, move PRD-related canonical docs to project-local imported cache.
  local archive_root="${factory_project_root}/_imported/docs"
  local arc_prd="${archive_root}/prd/$(basename "${src_prd}")"
  mkdir -p "$(dirname "${arc_prd}")"
  mv -f "${src_prd}" "${arc_prd}"
  archived+=("${arc_prd}")

  if [[ -n "${src_b}" ]]; then
    local arc_b="${archive_root}/contract/specs/$(basename "${src_b}")"
    mkdir -p "$(dirname "${arc_b}")"
    mv -f "${src_b}" "${arc_b}"
    archived+=("${arc_b}")
  fi

  if [[ -n "${src_c}" ]]; then
    local arc_c="${archive_root}/contract/intent_maps/$(basename "${src_c}")"
    mkdir -p "$(dirname "${arc_c}")"
    mv -f "${src_c}" "${arc_c}"
    archived+=("${arc_c}")
  fi

  if [[ -n "${src_d}" ]]; then
    local arc_d="${archive_root}/platform/$(basename "${src_d}")"
    mkdir -p "$(dirname "${arc_d}")"
    mv -f "${src_d}" "${arc_d}"
    archived+=("${arc_d}")
  fi

  if [[ -n "${src_adr}" ]]; then
    local arc_adr="${archive_root}/adr/$(basename "${src_adr}")"
    mkdir -p "$(dirname "${arc_adr}")"
    mv -f "${src_adr}" "${arc_adr}"
    archived+=("${arc_adr}")
  fi

  echo
  echo "PUSH completed successfully."
  echo "Project: ${project}"
  echo "PRD: ${prd_file}"
  echo "Updated in repo:"
  print_list copied
  echo "Moved to imported cache:"
  print_list archived
}

run_pull() {
  local project="$1"
  local prd_num="$2"
  local factory_project_root="$3"
  local main_project_root="$4"

  local base=""
  base="$(git -C "${main_project_root}" merge-base HEAD origin/main 2>/dev/null || true)"
  if [[ -z "${base}" ]]; then
    base="$(git -C "${main_project_root}" merge-base HEAD main 2>/dev/null || true)"
  fi

  if [[ -z "${base}" ]]; then
    echo "ERROR: merge-base calculation failed."
    echo "       Check branch / remote state in ${main_project_root} (origin/main or main)."
    exit 1
  fi

  mapfile -t changed_docs < <(git -C "${main_project_root}" diff --name-only "${base}"...HEAD -- docs/ | awk 'NF')

  if [[ ${#changed_docs[@]} -eq 0 ]]; then
    echo "변경 없음"
    exit 0
  fi

  local filtered=()
  local rel=""
  for rel in "${changed_docs[@]}"; do
    if ! is_allowed_pull_path "${rel}"; then
      continue
    fi
    if ! is_selected_prd_path "${rel}" "${prd_num}"; then
      continue
    fi
    filtered+=("${rel}")
  done

  if [[ ${#filtered[@]} -eq 0 ]]; then
    echo "변경 없음"
    exit 0
  fi

  local to_canonical=()
  local to_imported=()
  local canonical_entries=()
  local imported_entries=()
  local src_abs dst_abs

  local imported_prd_root="${IMPORTED_ROOT}/${project}/PRD-${prd_num}"

  for rel in "${filtered[@]}"; do
    src_abs="${main_project_root}/${rel}"

    # PULL 삭제 반영은 OFF: 삭제/누락 파일은 스킵
    if [[ ! -f "${src_abs}" ]]; then
      echo "[PULL] skip deleted/missing: ${rel}"
      continue
    fi

    case "${rel}" in
      docs/governance/*|docs/repomap/*)
        dst_abs="${factory_project_root}/${rel}"
        to_canonical+=("${rel}")
        canonical_entries+=("${src_abs}|${dst_abs}")
        ;;
      *)
        dst_abs="${imported_prd_root}/${rel}"
        to_imported+=("${rel}")
        imported_entries+=("${src_abs}|${dst_abs}")
        ;;
    esac
  done

  if [[ ${#canonical_entries[@]} -eq 0 && ${#imported_entries[@]} -eq 0 ]]; then
    echo "변경 없음"
    exit 0
  fi

  echo
  echo "[PULL] to canonical:"
  if [[ ${#to_canonical[@]} -eq 0 ]]; then
    echo "  - (none)"
  else
    print_list to_canonical
  fi

  echo "[PULL] to imported:"
  if [[ ${#to_imported[@]} -eq 0 ]]; then
    echo "  - (none)"
  else
    print_list to_imported
  fi

  local entry src dst
  for entry in "${canonical_entries[@]}"; do
    IFS='|' read -r src dst <<< "${entry}"
    mkdir -p "$(dirname "${dst}")"
    cp -f "${src}" "${dst}"
  done

  for entry in "${imported_entries[@]}"; do
    IFS='|' read -r src dst <<< "${entry}"
    mkdir -p "$(dirname "${dst}")"
    cp -f "${src}" "${dst}"
  done

  echo
  echo "PULL completed successfully."
  echo "Project: ${project}"
  echo "PRD: PRD-${prd_num}"
}

echo "== PRD Docs Sync UI =="
echo "Factory root: ${FACTORY_ROOT}"

echo
mapfile -t project_dirs < <(
  find "${FACTORY_ROOT}" -mindepth 1 -maxdepth 1 -type d \
    ! -name '.*' \
    ! -name 'bin' \
    ! -name 'launcher' \
    ! -name 'docs' \
    ! -name '_imported' \
    ! -name 'imported' \
    | sort
)

projects=()
for dir in "${project_dirs[@]}"; do
  if [[ -d "${dir}/docs/prd" ]]; then
    projects+=("$(basename "${dir}")")
  fi
done

if [[ ${#projects[@]} -eq 0 ]]; then
  echo "No projects found. Expected: <factory>/<project>/docs/prd"
  exit 1
fi

echo "Select project:"
select_from_list project "Project number?" "${projects[@]}"

factory_project_root="${FACTORY_ROOT}/${project}"
main_project_root="${MAIN_ROOT}/${project}"

if [[ ! -d "${main_project_root}" ]]; then
  echo "Main repo not found: ${main_project_root}"
  exit 1
fi

echo
echo "Select mode:"
select_from_list mode "Mode number?" "PUSH (factory -> repo)" "PULL (repo -> factory)"

if [[ "${mode}" == PUSH* ]]; then
  mapfile -t prd_candidates < <(
    find "${factory_project_root}/docs/prd" -mindepth 1 -maxdepth 1 -type f -name 'PRD-*.md' -printf '%f\n' 2>/dev/null \
      | awk 'NF' | sort -u -V
  )
else
  mapfile -t prd_candidates < <(
    find "${main_project_root}/docs/prd" -mindepth 1 -maxdepth 1 -type f -name 'PRD-*.md' -printf '%f\n' 2>/dev/null \
      | awk 'NF' | sort -u -V
  )
fi

if [[ ${#prd_candidates[@]} -eq 0 ]]; then
  if [[ "${mode}" == PUSH* ]]; then
    echo "No PRD candidates found in factory canonical docs/prd"
  else
    echo "No PRD candidates found in repo docs/prd"
  fi
  exit 1
fi

echo
echo "Select PRD:"
select_from_list prd_file "PRD number?" "${prd_candidates[@]}"


# Defensive trim for accidental CR/LF in selection output
prd_file="${prd_file//$'\r'/}"
prd_file="${prd_file//$'\n'/}"
if [[ ! "${prd_file}" =~ ^PRD-[0-9]+_.+\.md$ ]]; then
  echo "Invalid PRD filename format: ${prd_file}"
  echo "Expected: PRD-<N>_<action>.md"
  exit 1
fi

prd_num="${prd_file#PRD-}"
prd_num="${prd_num%%_*}"

if [[ ! "${prd_num}" =~ ^[0-9]+$ ]]; then
  echo "Invalid PRD number: ${prd_num}"
  exit 1
fi

if [[ "${mode}" == PUSH* ]]; then
  run_push "${project}" "${prd_file}" "${prd_num}" "${factory_project_root}" "${main_project_root}"
else
  run_pull "${project}" "${prd_num}" "${factory_project_root}" "${main_project_root}"
fi

