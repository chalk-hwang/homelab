#!/bin/zsh

# 프로젝트의 단일 .env 파일 경로
PROJECT_ENV="./stack.env"

# 기존 단일 .env 파일 초기화
echo "# Merged .env file" >"$PROJECT_ENV"

# apps 디렉토리 경로
APPS_DIR="./apps"

# 임시 딕셔너리를 위한 배열 초기화
declare -A env_dict

# 디렉토리 내 모든 .env 파일 순회
for env_file in "$APPS_DIR"/*/.env; do
	# 컨테이너 이름 추출
	container_name=$(basename "$(dirname "$env_file")")

	# 현재 .env 파일 읽기
	while IFS= read -r line || [ -n "$line" ]; do
		# 공백 라인 및 주석 무시
		[[ -z $line || $line =~ ^# ]] && continue

		# 변수명과 값 분리 (zsh에서는 sed 사용)
		key=$(echo "$line" | sed 's/=.*//')
		value=$(echo "$line" | sed 's/^[^=]*=//')

		# 기존 딕셔너리에 같은 변수명이 있는지 확인
		if [[ -n ${env_dict[$key]} ]]; then
			if [[ ${env_dict[$key]} != "$value" ]]; then
				# 값이 다를 경우 변수명 치환
				new_key="$(echo "${container_name}_${key}" | tr '[:lower:]' '[:upper:]' | tr -s '[:punct:]' '_')"
				env_dict["$new_key"]="$value"
				echo "$new_key=$value" >>"$PROJECT_ENV"
			fi
		else
			# 값이 같거나 새로운 변수명일 경우
			env_dict["$key"]="$value"
			echo "$key=$value" >>"$PROJECT_ENV"
		fi
	done <"$env_file"
done

echo "모든 .env 파일이 병합되었습니다: $PROJECT_ENV"
