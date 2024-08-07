-- Copyright (c) 2024 StackQL Studios, MIT License
-- https://github.com/stackql

.load dist/split_part

-- Test for null inputs
select '1_01', split_part(null, '/', 1) is null;
select '1_02', split_part('a/b/c', null, 1) is null;
select '1_03', split_part('a/b/c', '/', null) is null;

-- Test for basic splitting
select '2_01', split_part('a/b/c', '/', 1) = 'a';
select '2_02', split_part('a/b/c', '/', 2) = 'b';
select '2_03', split_part('a/b/c', '/', 3) = 'c';

-- Test for separators at the beginning and end
select '3_01', split_part('/a/b/c/', '/', 1) = '';
select '3_02', split_part('/a/b/c/', '/', 2) = 'a';
select '3_03', split_part('/a/b/c/', '/', 4) = 'c';
select '3_04', split_part('/a/b/c/', '/', 5) = '';

-- Test for negative indexing
select '4_01', split_part('a/b/c', '/', -1) = 'c';
select '4_02', split_part('a/b/c', '/', -2) = 'b';
select '4_03', split_part('a/b/c', '/', -3) = 'a';

-- Test for multiple consecutive separators
select '5_01', split_part('a//b/c', '/', 1) = 'a';
select '5_02', split_part('a//b/c', '/', 2) = '';
select '5_03', split_part('a//b/c', '/', 3) = 'b';

-- Test for out-of-range index
select '6_01', split_part('a/b/c', '/', 4) is null;
select '6_02', split_part('a/b/c', '/', -4) is null;

-- Test with different separators
select '7_01', split_part('a-b-c', '-', 2) = 'b';
select '7_02', split_part('a#b#c', '#', 3) = 'c';

-- Test with non-alphanumeric separators
select '8_01', split_part('a$b$c', '$', 2) = 'b';
select '8_02', split_part('a.b.c', '.', 3) = 'c';

-- Test for empty string
select '9_01', split_part('', '/', 1) = '';
select '9_02', split_part('', '/', -1) = '';

-- Test for single character source
select '10_01', split_part('a', '/', 1) = 'a';
select '10_02', split_part('a', '/', 2) is null;
select '10_03', split_part('a', '/', -1) = 'a';
