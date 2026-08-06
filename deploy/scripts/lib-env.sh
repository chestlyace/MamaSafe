#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# MamaSafe — shared helper for loading deploy/.env.production
#
# Sourced by the deploy scripts. `load_env FILE` parses KEY=VALUE
# lines and exports them WITHOUT executing them (safe for values with
# spaces, quotes, or '='). Existing exported variables are preserved
# (do not clobber), so operators can override on the command line.
# ═══════════════════════════════════════════════════════════════

load_env() {
    local file="${1:?load_env: missing file argument}"
    local line key value

    if [[ ! -r "${file}" ]]; then
        echo "ERROR: env file not readable: ${file}" >&2
        return 1
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Skip blank lines and comments
        [[ -z "${line}" || "${line}" == \#* ]] && continue
        # Keep only KEY=VALUE lines
        [[ "${line}" != *=* ]] && continue

        key="${line%%=*}"
        value="${line#*=}"

        # Trim whitespace around the key
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"

        # Strip trailing CR (Windows-edited files)
        value="${value%$'\r'}"

        # Strip one pair of surrounding quotes
        if [[ "${#value}" -ge 2 ]]; then
            if [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]] \
            || [[ "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
                value="${value:1:${#value}-2}"
            fi
        fi

        # Do not overwrite values already exported in the environment
        if [[ -n "${key}" && -z "${!key+x}" ]]; then
            export "${key}=${value}"
        fi
    done < "${file}"
}
