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

# Ensure `docker compose` can interpolate ${VAR} references from
# .env.production. Compose reads a plain `.env` in the project directory
# for interpolation (env_file: does NOT feed interpolation), so link
# deploy/.env -> .env.production. Call this before any compose command.
ensure_compose_env() {
    local compose_dir="${1:?ensure_compose_env: missing compose_dir argument}"
    local link="${compose_dir}/.env"
    local target="${compose_dir}/.env.production"

    if [[ ! -f "${target}" ]]; then
        echo "ERROR: ${target} missing — copy from .env.production.example and fill in values." >&2
        return 1
    fi

    if [[ ! -e "${link}" ]]; then
        ln -s ".env.production" "${link}"
        echo "==> Linked ${link} -> .env.production (for compose interpolation)"
    elif [[ ! -L "${link}" || "$(readlink "${link}")" != ".env.production" ]]; then
        echo "WARN: ${link} exists and is not a symlink to .env.production;" >&2
        echo "      compose interpolation may use stale values." >&2
    fi
}
