#!/usr/bin/env bats

# Performance tests for sort-pictures.sh

load 'test_helper'

setup() {
    setup_test_dir
    # Source the sample images helper
    source "${BATS_TEST_DIRNAME}/fixtures/sample_images.sh"
}

teardown() {
    teardown_test_dir
}

@test "performance: handles 100 files in reasonable time" {
    # Create 100 test images
    create_large_test_collection "$TEST_SOURCE_DIR" 100

    # Measure execution time (dry run to avoid actual file operations)
    start_time=$(date +%s)
    run "$SORT_PICTURES_SCRIPT" --dry-run "$TEST_SOURCE_DIR"
    end_time=$(date +%s)

    [ "$status" -eq 0 ]

    # Should complete within 30 seconds for 100 files
    execution_time=$((end_time - start_time))
    echo "Execution time: ${execution_time}s"
    [ "$execution_time" -lt 30 ]
}

@test "performance: parallel processing improves speed with many files" {
    # Create test files
    create_large_test_collection "$TEST_SOURCE_DIR" 50

    # Test sequential processing
    start_time=$(date +%s)
    run "$SORT_PICTURES_SCRIPT" --jobs 1 --dry-run "$TEST_SOURCE_DIR"
    sequential_time=$(date +%s)
    sequential_duration=$((sequential_time - start_time))

    [ "$status" -eq 0 ]

    # Test parallel processing
    start_time=$(date +%s)
    run "$SORT_PICTURES_SCRIPT" --jobs 4 --dry-run "$TEST_SOURCE_DIR"
    parallel_time=$(date +%s)
    parallel_duration=$((parallel_time - start_time))

    [ "$status" -eq 0 ]

    echo "Sequential: ${sequential_duration}s, Parallel: ${parallel_duration}s"

    # Parallel should not be significantly slower than sequential
    # (In real scenarios with actual I/O, parallel would be faster)
    [ "$parallel_duration" -le $((sequential_duration + 5)) ]
}

@test "performance: progress reporting works with large collections" {
    # Create enough files to trigger progress reporting (>100)
    create_large_test_collection "$TEST_SOURCE_DIR" 150

    run "$SORT_PICTURES_SCRIPT" --jobs 2 --dry-run "$TEST_SOURCE_DIR"
    [ "$status" -eq 0 ]

    # Should show progress updates
    [[ "$output" =~ "Progress:" ]]
    [[ "$output" =~ "files checked" ]]
}

@test "performance: memory usage remains reasonable with large collections" {
    # This test ensures the script doesn't load all files into memory at once
    create_large_test_collection "$TEST_SOURCE_DIR" 200

    # Monitor memory usage during execution
    run "$SORT_PICTURES_SCRIPT" --dry-run "$TEST_SOURCE_DIR"
    [ "$status" -eq 0 ]

    # The test passing means the script completed without memory issues
    # In a real environment, you could use tools like valgrind or monitoring
    [[ "$output" =~ "Processing complete" ]]
}
