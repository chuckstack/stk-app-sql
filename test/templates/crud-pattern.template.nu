# === Testing CRUD operations ===
# Template: Replace MODULE with your module name (e.g., item, bp, project)
# Template Version: 2025-01-08
# Optional: Add --type-search-key TYPE_KEY if module has types

# print "=== Testing MODULE overview command ==="
# Note: Module commands are nushell functions, not external commands, so we can't use complete
# Verify command exists and returns non-empty string
let overview_result = MODULE
assert (($overview_result | str length) > 0) "Overview command should return non-empty text"

# print "=== Testing MODULE creation ==="
let created = (MODULE new $"Test MODULE($test_suffix)")
assert (($created | describe | str starts-with "record")) "Should return a record"
assert ($created.uu | is-not-empty) "Should have UUID"
assert ($created.name | str contains $test_suffix) "Name should contain test suffix"

# print "=== Testing MODULE list ==="
let list_result = (MODULE list)
assert ($list_result | where name =~ $test_suffix | is-not-empty) "Should find created MODULE"

# print "=== Testing MODULE get ==="
let get_result = ($created.uu | MODULE get)
assert ($get_result.uu == $created.uu) "Should get correct record"

# print "=== Testing MODULE revoke ==="
let revoke_result = ($created.uu | MODULE revoke)
assert ($revoke_result.is_revoked.0 == true) "Should be revoked"

# print "=== Testing MODULE list --all ==="
let all_list = (MODULE list --all | where name =~ $test_suffix)
assert ($all_list | where is_revoked == true | is-not-empty) "Should show revoked records"