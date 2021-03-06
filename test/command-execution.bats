#!/usr/bin/env bats

@test "calling convert-footage with illegal arguments reports an error and prints usage" {
	run ./convert-footage -x
	[ "$status" -eq 1 ]
	# get first line of output (includes std::err)
	first_line=$(echo "${output}" | head -1)
	# assert first line matches expected output substring
	# this prevents color codes from producing a failure as opposed to
	# a check like this: "${first_line}" = "Invalid option:x"
  [[ "${first_line}" == *"Invalid option: x"* ]]
  assert_usage_in "${output}"
}

assert_usage_in() {
	local output="$1"
	[[ "${output}" == *"####"* ]]
  [[ "${output}" == *"Usage"* ]]
  [[ "${output}" == *"Options"* ]]
}

@test "calling convert-footage with -h prints usage to std::out" {
	run ./convert-footage -h
	[ "$status" -eq 0 ]
	assert_usage_in "${output}"
}

@test "calling convert-footage with -e prints examples to std::out" {
	run ./convert-footage -e
	[ "$status" -eq 0 ]
	assert_examples_in "${output}"
}

assert_examples_in() {
	local output="$1"
	[[ "${output}" == *"# Convert current folder with best quality"* ]]
	[[ "${output}" == *"# Convert the current folder with quality 1"* ]]
	[[ "${output}" == *"# Convert folder ../myvideos with best quality (default)"* ]]
	[[ "${output}" == *"# Convert file ./myvideo.mp4 with quality 1"* ]]
	[[ "${output}" == *"# Show help"* ]]
}

@test "calling convert-footage with illegal -q value reports useful error message" {
	local expected="Quality needs to be a positive integer. The lower the value, the better the quality."
	run ./convert-footage -q a
	[ "$status" -eq 1 ]
	[[ "${output}" == *"${expected}"* ]]

	run ./convert-footage -q -1
	[ "$status" -eq 1 ]
	[[ "${output}" == *"${expected}"* ]]

	run ./convert-footage -q
	[ "$status" -eq 1 ]
	assert_usage_in "${output}"
}


@test "it doesn't convert files that are no videos and it returns with code 0 when searching a folder" {
	local test_dir="$(prepare_test_dir "convert-footage-2")"
	# Given we have a file with mp4 suffix, that is not really a video
	cp "test/fixtures/not-a-video.mp4" "${test_dir}/"
	# When we try to convert the folder
	run ./convert-footage "${test_dir}/"
	# We expect the program to terminate normally
	echo "${output}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *"Couldn't find any files to convert."* ]]
	# And we only expect the source file to be in the folder
	assert_file_count_in "${test_dir}" 1

	# Afterwards, we clean up the test directory
	remove_test_dir "${test_dir}"
}

prepare_test_dir() {
	local directory="$1"
	local target_dir="${BATS_TMPDIR}/${directory}"
	mkdir -p "${target_dir}"
	echo "${target_dir}"
}

assert_file_count_in() {
	local directory="$1"
	local expected=$2
	[ $(ls -1q "${directory}" | wc -l) -eq $expected ]
}

remove_test_dir() {
	local directory="$1"
	# make sure, we're in the TMPDIR, we don't want to end up with valuable files deleted because of a syntax error
	[[ "${directory}" == $BATS_TMPDIR* ]]
	rm -rf "${directory}"
}


@test "it can handle file- and foldernames with spaces" {
	local test_dir="$(prepare_test_dir "convert-footage-3")"
	# Given we have a file and folder with spaces in the name
	cp -R "test/fixtures/folder with spaces" "${test_dir}"
	assert_file_count_in "${test_dir}" 1

	# When we convert the folder
	run ./convert-footage "${test_dir}/folder with spaces/"
	echo "${output}"
	# We expect the program to terminate normally
	[ "$status" -eq 0 ]
	# And we expect source file and the converted file to be in the folder
	assert_file_count_in "${test_dir}/folder with spaces" 2

	# Afterwards, we clean up the test directory
	remove_test_dir "${test_dir}"
}


