## aws_policy_equal

```text
aws_policy_equal(POLICY1, POLICY2)
```

Compares two AWS IAM policy JSON strings and returns 1 if they are semantically equivalent according to AWS IAM policy evaluation rules, 0 otherwise. This function handles the specific comparison rules for AWS policies, where certain elements (like Action, Resource, and Principal) are treated as unordered sets.

```sql
-- Compare identical policies
SELECT aws_policy_equal(
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}',
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}'
); -- Returns 1 (true)

-- Compare policies with different Action ordering
SELECT aws_policy_equal(
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:PutObject"],"Resource":"*"}]}',
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:PutObject","s3:GetObject"],"Resource":"*"}]}'
); -- Returns 1 (true)

-- Compare policies with different Principal formats
SELECT aws_policy_equal(
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:role/role1"},"Action":"sts:AssumeRole"}]}',
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["arn:aws:iam::123456789012:role/role1"]},"Action":"sts:AssumeRole"}]}'
); -- Returns 1 (true)

-- Compare different policies
SELECT aws_policy_equal(
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject"],"Resource":"*"}]}',
  '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":["s3:GetObject"],"Resource":"*"}]}'
); -- Returns 0 (false)
```

### Key Features

- **Semantic Policy Comparison:** Compares AWS IAM policies according to AWS evaluation rules.
- **Unordered Arrays:** Treats arrays in fields like `Action`, `Resource`, and `Principal` as unordered sets.
- **Principal Format Support:** Handles both string and array formats for principals and other elements.
- **Condition Block Handling:** Correctly compares condition blocks regardless of key order.
- **Case-Insensitive ARNs:** Performs case-insensitive comparison for service names in ARNs.

### Supported Policy Types

- **IAM Policies:** Identity-based policies attached to IAM roles, users, and groups.
- **Trust Policies:** Resource-based policies that define which principals can assume an IAM role.
- **S3 Bucket Policies:** Resource-based policies attached to S3 buckets.

### Installation and Usage

SQLite command-line interface:

```
sqlite> .load ./aws_policy_equal.so
sqlite> SELECT aws_policy_equal(
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}',
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}'
);
```

### Implementation Details

The `aws_policy_equal` function is implemented using the [cJSON library](https://github.com/DaveGamble/cJSON) and includes specialized comparison logic for AWS policy elements. It is part of the StackQL extension suite for SQLite, providing enhanced cloud policy management capabilities.

[⬇️ Download](https://github.com/stackql/stackql/releases/latest) •
[✨ Explore](https://github.com/stackql/stackql) •
[🚀 Follow](https://github.com/stackql)