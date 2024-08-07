.load ./dist/json_equal

-- Test for identical JSON objects
select '2_01', json_equal('{"key": "value"}', '{"key": "value"}') = 1;
select '2_02', json_equal('{"key1": "value1", "key2": "value2"}', '{"key1": "value1", "key2": "value2"}') = 1;

-- Test for equivalent JSON objects with different key order
select '3_01', json_equal('{"key1": "value1", "key2": "value2"}', '{"key2": "value2", "key1": "value1"}') = 1;

-- Test for non-equivalent JSON objects
select '4_01', json_equal('{"key": "value"}', '{"key": "different"}') = 0;
select '4_02', json_equal('{"key1": "value1"}', '{"key2": "value2"}') = 0;

-- Test for identical JSON arrays
select '5_01', json_equal('[1, 2, 3]', '[1, 2, 3]') = 1;
select '5_02', json_equal('[{"key": "value"}]', '[{"key": "value"}]') = 1;

-- Test for non-equivalent JSON arrays
select '6_01', json_equal('[1, 2, 3]', '[3, 2, 1]') = 0;
select '6_02', json_equal('[{"key": "value"}]', '[{"key": "different"}]') = 0;

-- Test for complex JSON structures
select '7_01', json_equal('{"key": [1, 2, {"subkey": "subvalue"}]}', '{"key": [1, 2, {"subkey": "subvalue"}]}') = 1;
select '7_02', json_equal('{"key": [1, 2, {"subkey": "subvalue1"}]}', '{"key": [1, 2, {"subkey": "subvalue2"}]}') = 0;

-- Test for whitespace differences
select '8_01', json_equal('{"key": "value"}', ' { "key" : "value" } ') = 1;
select '8_02', json_equal('[1, 2, 3]', '[ 1, 2, 3 ]') = 1;

-- Test for JSON with special characters
select '9_01', json_equal('{"key": "value with space"}', '{"key": "value with space"}') = 1;
select '9_02', json_equal('{"key": "value\nwith\nnewlines"}', '{"key": "value\nwith\nnewlines"}') = 1;
