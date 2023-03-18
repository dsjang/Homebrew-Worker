#!/bin/sh

############################################################
# Private
############################################################

DEFAULT_DUMP_FILE_PATH="${PWD}/brewfile"

function spinner() {
    local i
    local sp='/-\|'
    local n=${#sp}

    while sleep 0.1; do
        printf "%s\b" "${sp:i++%n:1}"
    done
}


############################################################
# Private - Menu
############################################################

function install_brew() {
    local install_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

    command -v brew >/dev/null 2>&1 && echo >&2 "already exist Homebrew" || { echo >&2 "install Homebrew"; /bin/bash -c "$(curl -fsSL ${install_URL})"; }
}

function regist_path() {

    if [[ $(sysctl -n machdep.cpu.brand_string) == *Intel* ]]; then
        echo >&2 "Not required regist path"
        return 0
    fi

    echo >&2 "regist path"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

function install_mas() {
    command -v mas >/dev/null 2>&1 && echo >&2 "already exist mas" || { echo >&2 "install mas"; /bin/bash "$(brew install mas)"; }
}

function import_dump_file() {
    read -p "백업 파일 경로를 입력해주세요(기본값: "${DEFAULT_DUMP_FILE_PATH}") : " -e path

    local file_path=$([ -z "${path}" ] && echo "${DEFAULT_DUMP_FILE_PATH}" || echo "${path}")

    if ! [[ -f $file_path ]]; then
        echo >&2 "\033[1;91m백업 파일 경로가 잘못됐습니다.\033[0m"
        return 0
    fi

    brew bundle --file="${file_path}"

    echo >&2 "백업 설치 완료: ${file_path}"
}

function export_dump_file() {
    read -p "백업 파일 경로를 입력해주세요(기본값: "${DEFAULT_DUMP_FILE_PATH}") : " -e path

    local file_path=$([ -z "${path}" ] && echo "${DEFAULT_DUMP_FILE_PATH}" || echo "${path}")

    local directory_path="${file_path%/*}"
    if ! [[ -d "${directory_path}" ]]; then
        mkdir -p "${directory_path}"
    fi

    brew bundle dump --force --file="${file_path}"

    echo >&2 "백업 완료: ${file_path}"
}

function search_application() {
    read -p "검색어 입력: " keyword

    if [[ -z "$keyword" ]]; then
        echo >&2 "\033[1;91m검색어를 입력해 주세요\033[0m"
        return 0
    fi

    spinner & 
    spinner_id=$!
    
    local results
    results+="$(brew search --cask "${keyword##* }")"
    results+="\n==> mases\n"
    results+="$(mas search "${keyword}")"

    { kill $spinner_id && wait $spinner_id; } 2>/dev/null

    echo >&2 "${results[*]}"
}

function install_application() {
    read -p "설치어(?) 입력: " install

    if [[ -z "$install" ]]; then
        echo >&2 "\033[1;91m설치어(?)를 입력해 주세요\033[0m"
        return 0
    fi

    local regex='^[0-9]+$'
    if [[ "$install" =~ $regex ]]; then
        echo >&2 "mas install: ${install}"
        mas install "${install}"
        return 0
    fi

    echo >&2 "cask install: ${install}"
    brew install --cask "${install}"
}


############################################################
# Questions
############################################################

function questions() {
    echo "
작업할 번호를 입력해 주세요
-----------------------------------------------------------------------
\033[1;34m[1]\033[0m Homebrew 설치  \033[1;34m[2]\033[0m 애플실리콘 path 등록  \033[1;34m[3]\033[0m mas 설치  \033[1;34m[4]\033[0m Brewfile 설치
-----------------------------------------------------------------------
\033[1;34m[5]\033[0m Application 검색  \033[1;34m[6]\033[0m Application 설치  \033[1;34m[7]\033[0m Brewfile 백업
-----------------------------------------------------------------------
\033[1;34m[8]\033[0m [1]+[2]+[3]  \033[1;34m[9]\033[0m [1]+[2]+[3]+[4]
-----------------------------------------------------------------------
\033[1;34m[0]\033[0m 종료
-----------------------------------------------------------------------"

    handle_questions_input
}

function handle_questions_input() {
    read -p answer

    echo >&2 "answer: >$answer<"

    if [ -z "$answer" ]; then
        echo >&2 "empty"
    else
        echo >&2 "WTF"
    fi

    case "$answer" in
        "1")
            install_brew
            questions
        ;;
        "2")
            regist_path
            questions
        ;;
        "3")
            install_mas
            questions
        ;;
        "4")
            import_dump_file
            questions
        ;;
        "5")
            search_application
            questions
        ;;
        "6")
            install_application
            questions
        ;;
        "7")
            export_dump_file
            questions
        ;;
        "8")
            install_brew
            regist_path
            install_mas
            questions
        ;;
        "9")
            install_brew
            regist_path
            install_mas
            import_dump_file
            questions
        ;;
        "0")
            echo >&2 "바이바이~ \(ㅇ_ㅇ)/"
            return 0
        ;;
        *)
            echo >&2 "\033[1;91m올바른 번호를 입력해 주세요\033[0m"
            questions
        ;;
    esac
}

############################################################
# Action
############################################################

questions
