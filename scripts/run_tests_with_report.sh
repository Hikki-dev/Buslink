#!/bin/bash

# Ensure junitreport is available
if ! command -v tojunit &> /dev/null; then
    echo "junitreport not found. Activating..."
    dart pub global activate junitreport
    PATH="$PATH":"$HOME/.pub-cache/bin"
fi

# Create directory for reports if it doesn't exist
mkdir -p test-results

echo "=================================================="
echo "Running Flutter Integration Tests with Report Gen"
echo "=================================================="

# Run the test and pipe to tojunit
# We use 'flutter test' for integration tests in this context to get the json output easily
# For strictly 'flutter integration_test', the output capture can be tricky, but 'flutter test integration_test/...' works for many setups.
# If this fails, we might need 'flutter drive' or specific integration_test commands.
# Using 'flutter test' allows standardized JSON output that tojunit parses.

echo "NOTE: Output is hidden while report is generating."
echo "This may take up to 60 minutes. Please be patient..."
flutter test integration_test/full_system_test.dart --timeout 60m --machine | tojunit --output test-results/report.xml

echo ""
echo "=================================================="
echo "Test run complete."
echo "Report generated at: test-results/report.xml"
echo "=================================================="
echo "To view the visual dashboard (requires Allure CLI):"
echo "  allure serve test-results"
echo "=================================================="
