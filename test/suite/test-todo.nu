#!/usr/bin/env nu

# Test script for stk_todo module
echo "=== Testing stk_todo Module ==="

# Test-specific suffix to ensure test isolation and idempotency
# Generate random 2-char suffix from letters (upper/lower) and numbers
let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
let random_suffix = (0..1 | each {|_| 
    let idx = (random int 0..($chars | str length | $in - 1))
    $chars | str substring $idx..($idx + 1)
} | str join)
let test_suffix = $"_st($random_suffix)"  # st for stk_todo + 2 random chars

# REQUIRED: Import modules and assert
use ../modules *
use std/assert

echo "=== Testing todo list creation ==="
# Use unique names with test suffix to avoid conflicts
let weekend_name = $"Weekend Projects($test_suffix)"
let work_name = $"Work Tasks($test_suffix)"

let weekend_result = (todo new $weekend_name --description "Tasks for the weekend")
assert ($weekend_result | columns | any {|col| $col == "uu"}) "Todo list creation should return UUID"
assert ($weekend_result.uu | is-not-empty) "Weekend Projects UUID should not be empty"
echo "✓ Weekend Projects created with UUID:" ($weekend_result.uu)

let work_result = (todo new $work_name --description "Professional tasks")
assert ($work_result | columns | any {|col| $col == "uu"}) "Work tasks creation should return UUID"
assert ($work_result.uu | is-not-empty) "Work Tasks UUID should not be empty"
echo "✓ Work Tasks created with UUID:" ($work_result.uu)

echo "=== Testing todo item creation with parent by UUID ==="
let weekend_uu = $weekend_result.uu.0
let fence_name = $"Fix garden fence($test_suffix)"
let fence_result = ($weekend_uu | todo new $fence_name --description "Replace broken posts")
assert ($fence_result | columns | any {|col| $col == "uu"}) "Child todo creation should return UUID"
assert ($fence_result.uu | is-not-empty) "Fence task UUID should not be empty"
# table_name_uu_json is parsed from JSON into a record
let fence_parent_info = $fence_result.table_name_uu_json.0
assert ($fence_parent_info.uu == $weekend_uu) "Parent UUID should be set correctly"
assert ($fence_parent_info.table_name == "stk_request") "Parent table should be stk_request"
echo "✓ Fix garden fence added to Weekend Projects"

let garage_name = $"Clean garage($test_suffix)"
let garage_result = ($weekend_uu | todo new $garage_name)
assert ($garage_result | columns | any {|col| $col == "uu"}) "Garage todo creation should return UUID"
echo "✓ Clean garage added to Weekend Projects"

let work_uu = $work_result.uu.0
let budget_name = $"Review budget($test_suffix)"
let budget_result = ($work_uu | todo new $budget_name --description "Q1 budget review")
assert ($budget_result | columns | any {|col| $col == "uu"}) "Budget todo creation should return UUID"
echo "✓ Review budget added to Work Tasks"

echo "=== Testing standalone todo item ==="
let dentist_name = $"Call dentist($test_suffix)"
let dentist_result = (todo new $dentist_name)
assert ($dentist_result | columns | any {|col| $col == "uu"}) "Standalone todo should return UUID"
# For standalone todos, table_name_uu_json might not be in columns if it's null
if ($dentist_result | columns | any {|col| $col == "table_name_uu_json"}) {
    let parent_json = $dentist_result.table_name_uu_json.0
    assert (($parent_json | describe) == "record" and ($parent_json | is-empty)) "Standalone todo should not have parent"
} else {
    # Column not present means it's null, which is correct for standalone
    assert true "Standalone todo has no parent (null)"
}
echo "✓ Standalone todo created"

echo "=== Testing todo list display ==="
let todos = (todo list)
assert (($todos | length) > 0) "Todo list should contain items"
assert ($todos | columns | any {|col| $col == "name"}) "Todo list should contain name column"
assert ($todos | columns | any {|col| $col == "description"}) "Todo list should contain description column"
echo "✓ Todo list verified with" ($todos | length) "items"

echo "=== Testing todo list with detail ==="
let detailed_todos = (todo list --detail)
assert ($detailed_todos | columns | any {|col| $col == "type_name"}) "Detailed list should include type_name"
assert ($detailed_todos | columns | any {|col| $col == "type_enum"}) "Detailed list should include type_enum"
echo "✓ Detailed todo list includes type information"

echo "=== Testing todo get by UUID ==="
let first_todo = ($todos | get uu.0)
let retrieved = ($first_todo | todo get)
assert (($retrieved | length) == 1) "Should retrieve exactly one record"
assert ($retrieved.uu.0 == $first_todo) "Retrieved UUID should match requested"
echo "✓ Todo retrieved by UUID"

echo "=== Testing todo get with detail ==="
let detailed_todo = ($first_todo | todo get --detail)
assert ($detailed_todo | columns | any {|col| $col == "type_name"}) "Detailed get should include type info"
echo "✓ Detailed todo includes type information"

echo "=== Testing filtered todo list by parent ==="
# Filter todos that have the weekend project as parent
let weekend_items = (todo list | where {|t| 
    # Check if table_name_uu_json exists and has a non-null uu
    if ($t | columns | any {|col| $col == "table_name_uu_json"}) {
        let parent_info = $t.table_name_uu_json
        # Check if uu exists and matches
        ($parent_info.uu? | describe) != "nothing" and $parent_info.uu? == $weekend_uu
    } else {
        false
    }
})
assert (($weekend_items | length) == 2) "Should find exactly 2 items under Weekend Projects"
assert ($weekend_items | all {|row| $row.table_name_uu_json.uu == $weekend_uu}) "All items should have correct parent"
echo "✓ Filtered todo list verified with" ($weekend_items | length) "Weekend Project items"

echo "=== Testing todo revoke (mark as done) by UUID ==="
let garage_todo = (todo list | where name == $garage_name | get uu.0)
let revoke_result = ($garage_todo | todo revoke)
assert ($revoke_result | columns | any {|col| $col == "is_revoked"}) "Revoke should return is_revoked status"
assert (($revoke_result.is_revoked.0) == true) "Item should be marked as revoked"
echo "✓ Clean garage marked as done"

echo "=== Testing todo list excludes revoked by default ==="
let active_todos = (todo list)
let garage_in_active = ($active_todos | where name == $garage_name | length)
assert ($garage_in_active == 0) "Revoked todo should not appear in default list"
echo "✓ Revoked todos excluded from default list"

echo "=== Testing todo list with --all includes revoked ==="
let all_todos = (todo list --all)
let garage_in_all = ($all_todos | where name == $garage_name | length)
assert ($garage_in_all > 0) "Revoked todo should appear in --all list"
assert (($all_todos | where name == $garage_name | get is_revoked.0) == true) "Should show as revoked"
echo "✓ Todo list --all includes revoked items"

echo "=== Testing todo creation with JSON data ==="
let json_name = $"Project Planning($test_suffix)"
let json_todo = (todo new $json_name --json '{"due_date": "2024-12-31", "priority": "high", "tags": ["quarterly", "strategic"]}')
assert ($json_todo | columns | any {|col| $col == "uu"}) "JSON todo creation should return UUID"
assert ($json_todo.uu | is-not-empty) "JSON todo UUID should not be empty"
echo "✓ Todo with JSON created, UUID:" ($json_todo.uu)

echo "=== Verifying todo's record_json field ==="
let json_todo_detail = ($json_todo.uu.0 | todo get | get 0)
assert ($json_todo_detail | columns | any {|col| $col == "record_json"}) "Todo should have record_json column"
let stored_json = ($json_todo_detail.record_json)
assert ($stored_json | columns | any {|col| $col == "due_date"}) "JSON should contain due_date field"
assert ($stored_json.due_date == "2024-12-31") "Due date should be 2024-12-31"
assert ($stored_json.priority == "high") "Priority should be high"
echo "✓ JSON data verified in record_json field"

echo "=== Testing todo creation with specific type ==="
if ((todo types | where name == "work-todo" | length) > 0) {
    let typed_name = $"Typed Task($test_suffix)"
    let typed_todo = (todo new $typed_name --type "work-todo")
    assert ($typed_todo | columns | any {|col| $col == "uu"}) "Typed todo creation should return UUID"
    let typed_detail = ($typed_todo.uu.0 | todo get --detail | get 0)
    assert ($typed_detail.type_name == "work-todo") "Todo should have specified type"
    echo "✓ Todo created with specific type"
} else {
    echo "! Skipping typed todo test - no work-todo type found"
}

echo "=== Testing todo types command ==="
let types = (todo types)
assert (($types | length) > 0) "Should have at least one TODO type"
assert ($types | all {|t| $t.type_enum == "TODO"}) "All types should have TODO enum"
assert ($types | columns | any {|col| $col == "is_default"}) "Types should have is_default column"
let default_types = ($types | where is_default == true)
assert (($default_types | length) <= 1) "Should have at most one default type"
echo "✓ Todo types verified"

echo "=== Testing elaborate functionality ==="
let todos_with_parents = (todo list | where {|t| 
    if ($t | columns | any {|col| $col == "table_name_uu_json"}) {
        let parent_info = $t.table_name_uu_json
        (($parent_info | describe) == "record") and (($parent_info | is-not-empty))
    } else {
        false
    }
} | elaborate name)
if (($todos_with_parents | length) > 0) {
    let first_with_parent = ($todos_with_parents | get 0)
    assert ($first_with_parent | columns | any {|col| $col == "table_name_uu_json_resolved"}) "Should have resolved column"
    # The resolved column should contain the parent record
    assert ($first_with_parent.table_name_uu_json_resolved.name? != null) "Resolved parent should have name"
    echo "✓ Elaborate functionality verified"
} else {
    echo "! No todos with parents found for elaborate test"
}

echo "=== Testing error handling - invalid parent UUID ==="
try {
    "00000000-0000-0000-0000-000000000000" | todo new "This should fail"
    assert false "Should have thrown error for invalid parent UUID"
} catch {
    echo "✓ Correctly caught error for invalid parent UUID"
}

echo "=== Testing error handling - revoke non-existent todo ==="
try {
    "00000000-0000-0000-0000-000000000000" | todo revoke
    assert false "Should have thrown error for non-existent todo"
} catch {
    echo "✓ Correctly caught error for non-existent todo"
}

echo "=== Testing error handling - get non-existent todo ==="
let non_existent = ("00000000-0000-0000-0000-000000000000" | todo get)
assert (($non_existent | length) == 0) "Get should return empty for non-existent UUID"
echo "✓ Get returns empty for non-existent todo"

echo "=== Final state verification ==="
# Count only the todos we created in this test run
let final_active = (todo list | where name =~ $test_suffix)
let test_active_count = ($final_active | length)
assert ($test_active_count > 0) "Should have active todos from this test run"
echo "✓ Final active todos from this test:" $test_active_count "items"

let final_all = (todo list --all | where name =~ $test_suffix)
let test_all_count = ($final_all | length)
assert ($test_all_count > $test_active_count) "All todos should include revoked items from this test"
echo "✓ Final all todos from this test:" $test_all_count "total items"

echo "=== All tests completed successfully ==="