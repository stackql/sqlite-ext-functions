-- Copyright (c) 2024 StackQL Studios, MIT License
-- https://github.com/stackql

.load dist/aws_policy_equal

-- Test for identical policy documents
SELECT '1_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}'
) = 1;

-- Test for statement order in policy (should be order-sensitive)
SELECT '2_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"},{"Effect":"Deny","Action":"ec2:*","Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"ec2:*","Resource":"*"},{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}'
) = 0;

-- Test for different policies
SELECT '2_02', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"s3:*","Resource":"*"}]}'
) = 0;

-- Test for unordered Action arrays
SELECT '3_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:PutObject"],"Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:PutObject","s3:GetObject"],"Resource":"*"}]}'
) = 1;

-- Test for unordered Resource arrays
SELECT '3_02', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":["arn:aws:s3:::mybucket","arn:aws:s3:::otherbucket"]}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":["arn:aws:s3:::otherbucket","arn:aws:s3:::mybucket"]}]}'
) = 1;

-- Test for Principal unordered arrays
SELECT '4_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["arn:aws:iam::123456789012:role/role1","arn:aws:iam::123456789012:role/role2"]},"Action":"s3:*","Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["arn:aws:iam::123456789012:role/role2","arn:aws:iam::123456789012:role/role1"]},"Action":"s3:*","Resource":"*"}]}'
) = 1;

-- Test for mixed principal types
SELECT '4_02', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:role/role1","Service":"lambda.amazonaws.com"},"Action":"s3:*","Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com","AWS":"arn:aws:iam::123456789012:role/role1"},"Action":"s3:*","Resource":"*"}]}'
) = 1;

-- Test for complex nested statements
SELECT '5_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["arn:aws:iam::123456789012:role/role1"]},"Action":["s3:GetObject","s3:PutObject"],"Resource":["arn:aws:s3:::bucket1/*","arn:aws:s3:::bucket2/*"],"Condition":{"StringEquals":{"aws:PrincipalTag/department":"HR"}}}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["arn:aws:iam::123456789012:role/role1"]},"Action":["s3:PutObject","s3:GetObject"],"Resource":["arn:aws:s3:::bucket2/*","arn:aws:s3:::bucket1/*"],"Condition":{"StringEquals":{"aws:PrincipalTag/department":"HR"}}}]}'
) = 1;

-- Test for external ID policy example from your conversation
SELECT '6_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Condition":{"StringEquals":{"sts:ExternalId":"0000"}},"Action":"sts:AssumeRole","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"}}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"},"Action":"sts:AssumeRole","Condition":{"StringEquals":{"sts:ExternalId":"0000"}}}]}'
) = 1;

-- Test for complex policy with multiple statements and different ordering
SELECT '7_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Sid":"Statement1","Effect":"Allow","Action":["ec2:DescribeInstances","ec2:StartInstances"],"Resource":"*"},{"Sid":"Statement2","Effect":"Deny","Action":"ec2:StopInstances","Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Sid":"Statement1","Effect":"Allow","Action":["ec2:StartInstances","ec2:DescribeInstances"],"Resource":"*"},{"Sid":"Statement2","Effect":"Deny","Action":"ec2:StopInstances","Resource":"*"}]}'
) = 1;

-- Test for case-insensitive service name comparison in ARNs
SELECT '8_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"arn:aws:s3:::mybucket"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"arn:aws:S3:::mybucket"}]}'
) = 1;

-- Test for array vs string representation of single values (AWS accepts both forms)
SELECT '9_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject"],"Resource":"*"}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"*"}]}'
) = 1;

-- Test for type coercion: number vs string (e.g. security group IpProtocol "-1" vs -1)
SELECT '11_01', aws_policy_equal(
    '[{"CidrIp":"0.0.0.0/0","Description":"Allow all outbound traffic","FromPort":-1,"ToPort":-1,"IpProtocol":"-1"}]',
    '[{"CidrIp":"0.0.0.0/0","Description":"Allow all outbound traffic","FromPort":-1,"IpProtocol":-1,"ToPort":-1}]'
) = 1;

-- Test for type coercion: string port number vs number
SELECT '11_02', aws_policy_equal(
    '[{"FromPort":"80","ToPort":"80","IpProtocol":"tcp"}]',
    '[{"FromPort":80,"ToPort":80,"IpProtocol":"tcp"}]'
) = 1;

-- Test for type coercion: boolean vs string (e.g. "true" vs true in conditions)
SELECT '11_03', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*","Condition":{"Bool":{"aws:SecureTransport":"true"}}}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*","Condition":{"Bool":{"aws:SecureTransport":true}}}]}'
) = 1;

-- Test for type coercion: false boolean vs string "false"
SELECT '11_04', aws_policy_equal(
    '{"enabled":"false"}',
    '{"enabled":false}'
) = 1;

-- Test for type coercion: different numeric values should NOT match
SELECT '11_05', aws_policy_equal(
    '[{"FromPort":"443","IpProtocol":"tcp"}]',
    '[{"FromPort":80,"IpProtocol":"tcp"}]'
) = 0;

-- Test for type coercion: non-numeric string should NOT match a number
SELECT '11_06', aws_policy_equal(
    '{"port":"all"}',
    '{"port":0}'
) = 0;

-- Test for different order of condition keys
SELECT '10_01', aws_policy_equal(
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*","Condition":{"StringEquals":{"aws:username":"johndoe"},"Bool":{"aws:SecureTransport":"true"}}}]}',
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*","Condition":{"Bool":{"aws:SecureTransport":"true"},"StringEquals":{"aws:username":"johndoe"}}}]}'
) = 1;