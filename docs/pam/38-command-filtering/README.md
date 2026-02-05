# 49 - Command Filtering and Restriction

## Table of Contents

1. [Command Filtering Overview](#command-filtering-overview)
2. [Architecture](#architecture)
3. [Filter Types](#filter-types)
4. [Pattern Syntax](#pattern-syntax)
5. [Common Dangerous Commands](#common-dangerous-commands)
6. [Filter Configuration](#filter-configuration)
7. [Pattern Examples Library](#pattern-examples-library)
8. [Testing Filters](#testing-filters)
9. [Handling Complex Commands](#handling-complex-commands)
10. [User Notification](#user-notification)
11. [Audit and Reporting](#audit-and-reporting)
12. [Troubleshooting](#troubleshooting)
13. [Best Practices](#best-practices)

---

## Command Filtering Overview

### What is Command Filtering?

Command filtering is a security feature in WALLIX Bastion that enables real-time analysis and control of commands executed during SSH and Telnet sessions. The Session Manager intercepts commands before they reach the target system, comparing them against predefined patterns to allow, deny, or audit specific actions.

For official documentation, see: https://pam.wallix.one/documentation

### Use Cases

| Use Case | Description | Filter Type |
|----------|-------------|-------------|
| Prevent accidental damage | Block destructive commands like `rm -rf /` | Blacklist |
| Enforce read-only access | Allow only read commands for auditors | Whitelist |
| Compliance auditing | Log all privileged commands without blocking | Audit-only |
| Separation of duties | Restrict DBAs to database commands only | Whitelist |
| Vendor access control | Limit third-party actions to specific scope | Whitelist |
| Emergency break-glass | Allow everything but log with alerts | Audit-only |

### Limitations

```
+==============================================================================+
|                     COMMAND FILTERING LIMITATIONS                             |
+==============================================================================+
|                                                                               |
|  PROTOCOL SUPPORT                                                             |
|  ================                                                             |
|                                                                               |
|  +-------------------+-------------------+----------------------------------+ |
|  | Protocol          | Filtering Support | Notes                            | |
|  +-------------------+-------------------+----------------------------------+ |
|  | SSH (Shell)       | Full              | Primary use case                 | |
|  | SSH (SCP/SFTP)    | Partial           | Filename patterns only           | |
|  | Telnet            | Full              | Same as SSH shell                | |
|  | RDP               | None              | Use application control instead  | |
|  | VNC               | None              | No command-level visibility      | |
|  | HTTP/HTTPS        | None              | Use URL filtering if needed      | |
|  +-------------------+-------------------+----------------------------------+ |
|                                                                               |
|  TECHNICAL LIMITATIONS                                                        |
|  =====================                                                        |
|                                                                               |
|  * Commands with aliases may bypass filters (e.g., alias ll='rm -rf')        |
|  * Binary/compiled programs cannot be filtered by argument                    |
|  * Scripts executed as single command only filter the script name            |
|  * Command substitution in shell may execute before filter evaluation        |
|  * Base64/hex encoded commands require decoding rules                        |
|  * Tab completion reveals commands before filter action                       |
|  * Filter evaluation adds ~2-5ms latency per command                          |
|                                                                               |
+==============================================================================+
```

---

## Architecture

### Command Filtering Flow

```
+==============================================================================+
|                      COMMAND FILTERING ARCHITECTURE                           |
+==============================================================================+
|                                                                               |
|     +----------+                                        +----------+          |
|     |   User   |                                        |  Target  |          |
|     |  Client  |                                        |  Server  |          |
|     +----+-----+                                        +----+-----+          |
|          |                                                   |                |
|          |  1. User types command                            |                |
|          |                                                   |                |
|          v                                                   |                |
|   +------+---------------------------------------------------+------+        |
|   |                     SESSION MANAGER                              |        |
|   |                                                                  |        |
|   |  +-----------------------------------------------------------+  |        |
|   |  |                  INPUT BUFFER                              |  |        |
|   |  |                                                            |  |        |
|   |  |  Receives keystroke stream from user                       |  |        |
|   |  |  Buffers until Enter key detected                          |  |        |
|   |  +------------------------------+----------------------------+  |        |
|   |                                 |                                |        |
|   |                                 | 2. Command complete            |        |
|   |                                 v                                |        |
|   |  +-----------------------------------------------------------+  |        |
|   |  |               COMMAND PARSER                               |  |        |
|   |  |                                                            |  |        |
|   |  |  * Tokenize command line                                   |  |        |
|   |  |  * Identify command and arguments                          |  |        |
|   |  |  * Handle pipes, redirects, semicolons                     |  |        |
|   |  |  * Detect command substitution                             |  |        |
|   |  +------------------------------+----------------------------+  |        |
|   |                                 |                                |        |
|   |                                 | 3. Parsed command              |        |
|   |                                 v                                |        |
|   |  +-----------------------------------------------------------+  |        |
|   |  |              FILTER ENGINE                                 |  |        |
|   |  |                                                            |  |        |
|   |  |  +-------------------------------------------------------+|  |        |
|   |  |  |  WHITELIST (if configured)                            ||  |        |
|   |  |  |  * Must match at least one allow rule                 ||  |        |
|   |  |  |  * No match = DENY                                    ||  |        |
|   |  |  +-------------------------------------------------------+|  |        |
|   |  |                            |                               |  |        |
|   |  |                            v                               |  |        |
|   |  |  +-------------------------------------------------------+|  |        |
|   |  |  |  BLACKLIST                                            ||  |        |
|   |  |  |  * Match any deny rule = BLOCK                        ||  |        |
|   |  |  |  * No match = proceed                                 ||  |        |
|   |  |  +-------------------------------------------------------+|  |        |
|   |  |                            |                               |  |        |
|   |  |                            v                               |  |        |
|   |  |  +-------------------------------------------------------+|  |        |
|   |  |  |  AUDIT RULES                                          ||  |        |
|   |  |  |  * Log matching commands                              ||  |        |
|   |  |  |  * Generate alerts if configured                      ||  |        |
|   |  |  |  * Always allow execution                             ||  |        |
|   |  |  +-------------------------------------------------------+|  |        |
|   |  +-----------------------------------------------------------+  |        |
|   |                                 |                                |        |
|   |              +------------------+------------------+             |        |
|   |              |                                     |             |        |
|   |              v                                     v             |        |
|   |        +-----------+                        +-----------+        |        |
|   |        |   ALLOW   |                        |   DENY    |        |        |
|   |        +-----------+                        +-----------+        |        |
|   |              |                                     |             |        |
|   |              v                                     v             |        |
|   |  4. Forward to target               5. Return error message      |        |
|   |                                         to user                  |        |
|   +------+---------------------------------------------------+------+        |
|          |                                                   |                |
|          v                                                   |                |
|   +------+-----+                                             |                |
|   |   Target   |<--------------------------------------------+                |
|   |   Server   |  (if ALLOW)                                                  |
|   +------------+                                                              |
|                                                                               |
+==============================================================================+
```

### Filter Evaluation Order

```
+==============================================================================+
|                     FILTER EVALUATION ORDER                                   |
+==============================================================================+
|                                                                               |
|                         Command Received                                      |
|                               |                                               |
|                               v                                               |
|                    +-------------------+                                      |
|                    | Global Whitelist  |                                      |
|                    | configured?       |                                      |
|                    +--------+----------+                                      |
|                             |                                                 |
|              +--------------+--------------+                                  |
|              |                             |                                  |
|             YES                           NO                                  |
|              |                             |                                  |
|              v                             |                                  |
|    +-------------------+                   |                                  |
|    | Command matches   |                   |                                  |
|    | whitelist?        |                   |                                  |
|    +--------+----------+                   |                                  |
|             |                              |                                  |
|      +------+------+                       |                                  |
|      |             |                       |                                  |
|     YES           NO                       |                                  |
|      |             |                       |                                  |
|      |             v                       |                                  |
|      |      +-----------+                  |                                  |
|      |      |   DENY    |                  |                                  |
|      |      | (not in   |                  |                                  |
|      |      | whitelist)|                  |                                  |
|      |      +-----------+                  |                                  |
|      |                                     |                                  |
|      +----------------------+--------------+                                  |
|                             |                                                 |
|                             v                                                 |
|                  +-------------------+                                        |
|                  | Command matches   |                                        |
|                  | blacklist?        |                                        |
|                  +--------+----------+                                        |
|                           |                                                   |
|                    +------+------+                                            |
|                    |             |                                            |
|                   YES           NO                                            |
|                    |             |                                            |
|                    v             |                                            |
|              +-----------+       |                                            |
|              |   DENY    |       |                                            |
|              | (blocked) |       |                                            |
|              +-----------+       |                                            |
|                                  |                                            |
|                                  v                                            |
|                       +-------------------+                                   |
|                       | Matches audit     |                                   |
|                       | rule?             |                                   |
|                       +--------+----------+                                   |
|                                |                                              |
|                         +------+------+                                       |
|                         |             |                                       |
|                        YES           NO                                       |
|                         |             |                                       |
|                         v             |                                       |
|                  +-------------+      |                                       |
|                  | LOG + ALERT |      |                                       |
|                  +------+------+      |                                       |
|                         |             |                                       |
|                         +------+------+                                       |
|                                |                                              |
|                                v                                              |
|                          +-----------+                                        |
|                          |   ALLOW   |                                        |
|                          +-----------+                                        |
|                                                                               |
+==============================================================================+
```

---

## Filter Types

### Whitelist (Allow Only)

Whitelists define an explicit set of allowed commands. Any command not matching the whitelist is automatically denied.

```
+==============================================================================+
|                         WHITELIST CONFIGURATION                               |
+==============================================================================+
|                                                                               |
|  USE CASES                                                                    |
|  =========                                                                    |
|                                                                               |
|  * Read-only access for auditors                                             |
|  * Restricted access for junior admins                                       |
|  * Vendor maintenance with specific scope                                    |
|  * Compliance-mandated access restrictions                                   |
|                                                                               |
|  BEHAVIOR                                                                     |
|  ========                                                                     |
|                                                                               |
|  +-------------------------+----------------------+                           |
|  | Command matches rule?   | Action               |                           |
|  +-------------------------+----------------------+                           |
|  | Yes                     | ALLOW (proceed)      |                           |
|  | No                      | DENY (block)         |                           |
|  +-------------------------+----------------------+                           |
|                                                                               |
+==============================================================================+
```

**Example Whitelist Configuration:**

```json
{
    "filter_name": "read-only-access",
    "filter_type": "whitelist",
    "description": "Allow only read and informational commands",
    "rules": [
        {
            "pattern": "ls",
            "pattern_type": "exact",
            "description": "List files"
        },
        {
            "pattern": "cat *",
            "pattern_type": "wildcard",
            "description": "View file contents"
        },
        {
            "pattern": "^(head|tail|less|more)\\s+",
            "pattern_type": "regex",
            "description": "File viewing commands"
        },
        {
            "pattern": "^(ps|top|df|free|uptime|who|w|id)$",
            "pattern_type": "regex",
            "description": "System information commands"
        }
    ]
}
```

### Blacklist (Deny Specific)

Blacklists define commands that are explicitly denied. All other commands are allowed by default.

```
+==============================================================================+
|                         BLACKLIST CONFIGURATION                               |
+==============================================================================+
|                                                                               |
|  USE CASES                                                                    |
|  =========                                                                    |
|                                                                               |
|  * Block dangerous commands for all users                                    |
|  * Prevent accidental system damage                                          |
|  * Enforce security policies                                                 |
|  * Protect specific files or directories                                     |
|                                                                               |
|  BEHAVIOR                                                                     |
|  ========                                                                     |
|                                                                               |
|  +-------------------------+----------------------+                           |
|  | Command matches rule?   | Action               |                           |
|  +-------------------------+----------------------+                           |
|  | Yes                     | DENY (block)         |                           |
|  | No                      | ALLOW (proceed)      |                           |
|  +-------------------------+----------------------+                           |
|                                                                               |
+==============================================================================+
```

**Example Blacklist Configuration:**

```json
{
    "filter_name": "dangerous-commands",
    "filter_type": "blacklist",
    "description": "Block dangerous and destructive commands",
    "rules": [
        {
            "pattern": "rm -rf /",
            "pattern_type": "contains",
            "description": "Prevent filesystem wipe"
        },
        {
            "pattern": "^(shutdown|reboot|poweroff|halt|init\\s+[06])\\b",
            "pattern_type": "regex",
            "description": "Prevent system shutdown/reboot"
        },
        {
            "pattern": "dd if=/dev/zero",
            "pattern_type": "contains",
            "description": "Prevent disk overwrite"
        }
    ]
}
```

### Audit-Only (Log But Allow)

Audit-only filters log and optionally alert on specific commands without blocking them.

```
+==============================================================================+
|                        AUDIT-ONLY CONFIGURATION                               |
+==============================================================================+
|                                                                               |
|  USE CASES                                                                    |
|  =========                                                                    |
|                                                                               |
|  * Monitor privileged command usage                                          |
|  * Compliance evidence collection                                            |
|  * Behavioral analysis before implementing restrictions                      |
|  * Security incident detection                                               |
|                                                                               |
|  BEHAVIOR                                                                     |
|  ========                                                                     |
|                                                                               |
|  +-------------------------+----------------------+                           |
|  | Command matches rule?   | Action               |                           |
|  +-------------------------+----------------------+                           |
|  | Yes                     | LOG + ALLOW          |                           |
|  | No                      | ALLOW (no log)       |                           |
|  +-------------------------+----------------------+                           |
|                                                                               |
|  ALERT OPTIONS                                                                |
|  =============                                                                |
|                                                                               |
|  * Email notification                                                        |
|  * SIEM event (syslog/CEF)                                                   |
|  * Webhook callback                                                          |
|  * Real-time dashboard alert                                                 |
|                                                                               |
+==============================================================================+
```

**Example Audit-Only Configuration:**

```json
{
    "filter_name": "privileged-command-audit",
    "filter_type": "audit",
    "description": "Log all privileged commands for compliance",
    "rules": [
        {
            "pattern": "^sudo\\s+",
            "pattern_type": "regex",
            "description": "Any sudo command",
            "alert": true,
            "alert_severity": "info"
        },
        {
            "pattern": "^(passwd|chpasswd|usermod|userdel|groupmod)",
            "pattern_type": "regex",
            "description": "User management commands",
            "alert": true,
            "alert_severity": "warning"
        },
        {
            "pattern": "(iptables|firewall-cmd|ufw)",
            "pattern_type": "contains",
            "description": "Firewall modifications",
            "alert": true,
            "alert_severity": "high"
        }
    ],
    "alert_config": {
        "email_recipients": ["security@company.com"],
        "syslog_enabled": true,
        "syslog_facility": "auth"
    }
}
```

---

## Pattern Syntax

### Pattern Types Overview

| Pattern Type | Syntax | Performance | Use Case |
|--------------|--------|-------------|----------|
| Exact | `shutdown` | Fastest | Single command, no args |
| Contains | `rm -rf` | Fast | Substring matching |
| Wildcard | `rm -rf *` | Medium | Simple patterns with * |
| Regex | `^rm\s+-rf\s+/` | Slowest | Complex patterns |

### Exact Match

Exact match compares the entire command line exactly as typed.

```
+==============================================================================+
|                           EXACT MATCH                                         |
+==============================================================================+
|                                                                               |
|  SYNTAX: command                                                              |
|                                                                               |
|  EXAMPLES                                                                     |
|  ========                                                                     |
|                                                                               |
|  Pattern: "shutdown"                                                          |
|                                                                               |
|  +---------------------------+----------+                                     |
|  | Command                   | Matches? |                                     |
|  +---------------------------+----------+                                     |
|  | shutdown                  | YES      |                                     |
|  | shutdown -h now           | NO       |                                     |
|  | /sbin/shutdown            | NO       |                                     |
|  | SHUTDOWN                  | NO       |                                     |
|  +---------------------------+----------+                                     |
|                                                                               |
|  BEST FOR                                                                     |
|  ========                                                                     |
|                                                                               |
|  * Simple commands without arguments                                         |
|  * Commands that must match exactly                                          |
|  * High-performance filtering needs                                          |
|                                                                               |
+==============================================================================+
```

### Wildcard Patterns

Wildcard patterns use `*` to match any characters and `?` to match single characters.

```
+==============================================================================+
|                         WILDCARD PATTERNS                                     |
+==============================================================================+
|                                                                               |
|  SYNTAX                                                                       |
|  ======                                                                       |
|                                                                               |
|  *   = Match zero or more characters                                         |
|  ?   = Match exactly one character                                           |
|                                                                               |
|  EXAMPLES                                                                     |
|  ========                                                                     |
|                                                                               |
|  Pattern: "rm -rf *"                                                          |
|                                                                               |
|  +---------------------------+----------+                                     |
|  | Command                   | Matches? |                                     |
|  +---------------------------+----------+                                     |
|  | rm -rf /                  | YES      |                                     |
|  | rm -rf /home/user         | YES      |                                     |
|  | rm -rf /var/log/*         | YES      |                                     |
|  | rm -f file.txt            | NO       |                                     |
|  | rm -rf                    | NO       |  (no trailing space + content)      |
|  +---------------------------+----------+                                     |
|                                                                               |
|  Pattern: "*.sh"                                                              |
|                                                                               |
|  +---------------------------+----------+                                     |
|  | Command                   | Matches? |                                     |
|  +---------------------------+----------+                                     |
|  | test.sh                   | YES      |                                     |
|  | /home/user/script.sh      | YES      |                                     |
|  | bash script.sh            | YES      |                                     |
|  | script.bash               | NO       |                                     |
|  +---------------------------+----------+                                     |
|                                                                               |
+==============================================================================+
```

### Regular Expressions

WALLIX Bastion supports PCRE (Perl Compatible Regular Expressions) for advanced pattern matching.

```
+==============================================================================+
|                      REGULAR EXPRESSIONS                                      |
+==============================================================================+
|                                                                               |
|  COMMON METACHARACTERS                                                        |
|  =====================                                                        |
|                                                                               |
|  +--------+------------------------------------------+                        |
|  | Symbol | Description                              |                        |
|  +--------+------------------------------------------+                        |
|  | ^      | Start of line                            |                        |
|  | $      | End of line                              |                        |
|  | .      | Any single character                     |                        |
|  | *      | Zero or more of previous                 |                        |
|  | +      | One or more of previous                  |                        |
|  | ?      | Zero or one of previous                  |                        |
|  | \s     | Whitespace character                     |                        |
|  | \S     | Non-whitespace character                 |                        |
|  | \w     | Word character [a-zA-Z0-9_]              |                        |
|  | \d     | Digit [0-9]                              |                        |
|  | \b     | Word boundary                            |                        |
|  | [...]  | Character class                          |                        |
|  | (...)  | Grouping                                 |                        |
|  | |      | Alternation (OR)                         |                        |
|  +--------+------------------------------------------+                        |
|                                                                               |
|  EXAMPLES                                                                     |
|  ========                                                                     |
|                                                                               |
|  Pattern: "^rm\s+-rf\s+/"                                                     |
|  Matches: rm -rf /  |  rm  -rf  /home  |  rm    -rf /var                     |
|  Rejects: rm -rf .  |  echo rm -rf /                                         |
|                                                                               |
|  Pattern: "^(shutdown|reboot|poweroff|halt)\b"                               |
|  Matches: shutdown  |  reboot  |  poweroff  |  halt                          |
|  Rejects: shutdownx |  my-reboot                                             |
|                                                                               |
|  Pattern: "chmod\s+(777|666)\s+"                                             |
|  Matches: chmod 777 file  |  chmod 666 /tmp/test                             |
|  Rejects: chmod 755 file  |  chmod 700 /home                                 |
|                                                                               |
|  Pattern: "(?i)password"                                                      |
|  Matches: password  |  PASSWORD  |  PassWord  (case-insensitive)             |
|                                                                               |
+==============================================================================+
```

### Case Sensitivity

```
+==============================================================================+
|                        CASE SENSITIVITY                                       |
+==============================================================================+
|                                                                               |
|  DEFAULT BEHAVIOR                                                             |
|  ================                                                             |
|                                                                               |
|  All pattern matching is CASE-SENSITIVE by default                           |
|                                                                               |
|  ENABLING CASE-INSENSITIVE MATCHING                                           |
|  ===================================                                          |
|                                                                               |
|  Method 1: Configuration option                                              |
|  --------------------------------                                             |
|                                                                               |
|  {                                                                            |
|      "pattern": "shutdown",                                                   |
|      "case_sensitive": false                                                  |
|  }                                                                            |
|                                                                               |
|  Method 2: Regex inline flag                                                 |
|  ---------------------------                                                  |
|                                                                               |
|  {                                                                            |
|      "pattern": "(?i)shutdown",                                               |
|      "pattern_type": "regex"                                                  |
|  }                                                                            |
|                                                                               |
|  RECOMMENDATION                                                               |
|  ==============                                                               |
|                                                                               |
|  * Linux/Unix: Usually case-sensitive (commands are lowercase)               |
|  * Windows: Case-insensitive matching recommended                            |
|  * Network devices: Varies by vendor (Cisco = case-insensitive)             |
|                                                                               |
+==============================================================================+
```

---

## Common Dangerous Commands

### Linux/Unix Dangerous Commands

```
+==============================================================================+
|                   LINUX/UNIX DANGEROUS COMMANDS                               |
+==============================================================================+
|                                                                               |
|  FILESYSTEM DESTRUCTION                                                       |
|  ======================                                                       |
|                                                                               |
|  +--------------------+-------------------------------------------------+    |
|  | Command Pattern    | Regex Pattern                                   |    |
|  +--------------------+-------------------------------------------------+    |
|  | rm -rf /           | ^rm\s+.*-r.*-f.*\s+/\s*$                       |    |
|  | rm -rf /*          | ^rm\s+.*-rf\s+/\*                               |    |
|  | rm -rf .           | ^rm\s+.*-rf\s+\.                                |    |
|  | rm -rf ~           | ^rm\s+.*-rf\s+~                                 |    |
|  | rm -rf *           | ^rm\s+.*-rf\s+\*                                |    |
|  +--------------------+-------------------------------------------------+    |
|                                                                               |
|  DISK/DEVICE OPERATIONS                                                       |
|  ======================                                                       |
|                                                                               |
|  +--------------------+-------------------------------------------------+    |
|  | Command            | Regex Pattern                                   |    |
|  +--------------------+-------------------------------------------------+    |
|  | dd if=/dev/zero    | dd\s+.*if=/dev/(zero|random|urandom)           |    |
|  | dd of=/dev/sd      | dd\s+.*of=/dev/sd[a-z]                          |    |
|  | mkfs               | ^mkfs\b                                         |    |
|  | mkswap             | ^mkswap\b                                       |    |
|  | fdisk              | ^fdisk\b                                        |    |
|  | parted             | ^parted\b                                       |    |
|  +--------------------+-------------------------------------------------+    |
|                                                                               |
|  SYSTEM CONTROL                                                               |
|  ==============                                                               |
|                                                                               |
|  +--------------------+-------------------------------------------------+    |
|  | Command            | Regex Pattern                                   |    |
|  +--------------------+-------------------------------------------------+    |
|  | shutdown           | ^(shutdown|poweroff|halt)\b                     |    |
|  | reboot             | ^reboot\b                                       |    |
|  | init 0             | ^init\s+[06]\b                                  |    |
|  | telinit 0          | ^telinit\s+[06]\b                               |    |
|  | systemctl poweroff | ^systemctl\s+(poweroff|reboot|halt)\b          |    |
|  +--------------------+-------------------------------------------------+    |
|                                                                               |
|  USER MANAGEMENT                                                              |
|  ===============                                                              |
|                                                                               |
|  +--------------------+-------------------------------------------------+    |
|  | Command            | Regex Pattern                                   |    |
|  +--------------------+-------------------------------------------------+    |
|  | userdel            | ^userdel\b                                      |    |
|  | groupdel           | ^groupdel\b                                     |    |
|  | passwd root        | ^passwd\s+root\b                                |    |
|  | usermod -L root    | ^usermod\s+.*-L.*\s+root\b                      |    |
|  | chsh               | ^chsh\b                                         |    |
|  +--------------------+-------------------------------------------------+    |
|                                                                               |
|  PRIVILEGE ESCALATION                                                         |
|  ====================                                                         |
|                                                                               |
|  +--------------------+-------------------------------------------------+    |
|  | Command            | Regex Pattern                                   |    |
|  +--------------------+-------------------------------------------------+    |
|  | chmod +s           | chmod\s+.*\+s                                   |    |
|  | chmod u+s          | chmod\s+[ugo]*\+s                               |    |
|  | setuid             | chown\s+root.*&&.*chmod\s+.*s                  |    |
|  | visudo             | ^visudo\b                                       |    |
|  | /etc/sudoers       | (vi|vim|nano|cat\s*>)\s+/etc/sudoers           |    |
|  +--------------------+-------------------------------------------------+    |
|                                                                               |
|  NETWORK CHANGES                                                              |
|  ===============                                                              |
|                                                                               |
|  +--------------------+-------------------------------------------------+    |
|  | Command            | Regex Pattern                                   |    |
|  +--------------------+-------------------------------------------------+    |
|  | iptables -F        | iptables\s+.*-F                                 |    |
|  | iptables -X        | iptables\s+.*-X                                 |    |
|  | ip route del       | ip\s+route\s+del                                |    |
|  | route del default  | route\s+del\s+default                           |    |
|  | ifconfig down      | ifconfig\s+\w+\s+down                           |    |
|  | systemctl stop ssh | systemctl\s+stop\s+(ssh|sshd|network)          |    |
|  +--------------------+-------------------------------------------------+    |
|                                                                               |
+==============================================================================+
```

### Windows Dangerous Commands

```
+==============================================================================+
|                    WINDOWS DANGEROUS COMMANDS                                 |
+==============================================================================+
|                                                                               |
|  FILESYSTEM OPERATIONS                                                        |
|  =====================                                                        |
|                                                                               |
|  +------------------------+---------------------------------------------+    |
|  | Command                | Regex Pattern (case-insensitive)            |    |
|  +------------------------+---------------------------------------------+    |
|  | format C:              | (?i)format\s+[a-z]:                         |    |
|  | del /F /S /Q C:\       | (?i)del\s+.*(/F|/S|/Q).*[a-z]:\\            |    |
|  | rd /S /Q C:\           | (?i)rd\s+/S\s+/Q\s+[a-z]:\\                 |    |
|  | rmdir /S /Q            | (?i)rmdir\s+/S\s+/Q                         |    |
|  +------------------------+---------------------------------------------+    |
|                                                                               |
|  SYSTEM CONTROL                                                               |
|  ==============                                                               |
|                                                                               |
|  +------------------------+---------------------------------------------+    |
|  | Command                | Regex Pattern                               |    |
|  +------------------------+---------------------------------------------+    |
|  | shutdown               | (?i)shutdown\s+(/s|/r|/t|/f)                |    |
|  | bcdedit                | (?i)bcdedit\b                               |    |
|  | reg delete             | (?i)reg\s+delete                            |    |
|  | sc stop                | (?i)sc\s+stop\b                             |    |
|  | net stop               | (?i)net\s+stop\b                            |    |
|  +------------------------+---------------------------------------------+    |
|                                                                               |
|  USER/GROUP MANAGEMENT                                                        |
|  =====================                                                        |
|                                                                               |
|  +------------------------+---------------------------------------------+    |
|  | Command                | Regex Pattern                               |    |
|  +------------------------+---------------------------------------------+    |
|  | net user /delete       | (?i)net\s+user\s+\w+\s+/delete              |    |
|  | net localgroup /delete | (?i)net\s+localgroup\s+\w+\s+/delete        |    |
|  | net user Administrator | (?i)net\s+user\s+Administrator              |    |
|  | wmic useraccount       | (?i)wmic\s+useraccount\s+.*delete           |    |
|  +------------------------+---------------------------------------------+    |
|                                                                               |
|  POWERSHELL DANGEROUS                                                         |
|  ====================                                                         |
|                                                                               |
|  +------------------------+---------------------------------------------+    |
|  | Command                | Regex Pattern                               |    |
|  +------------------------+---------------------------------------------+    |
|  | Remove-Item -Recurse   | (?i)Remove-Item\s+.*-Recurse.*-Force        |    |
|  | Stop-Computer          | (?i)Stop-Computer\b                         |    |
|  | Restart-Computer       | (?i)Restart-Computer\b                      |    |
|  | Disable-LocalUser      | (?i)Disable-LocalUser\b                     |    |
|  | Set-ExecutionPolicy    | (?i)Set-ExecutionPolicy\s+Bypass            |    |
|  | Invoke-Expression      | (?i)Invoke-Expression\b                     |    |
|  | IEX                    | (?i)\bIEX\b                                 |    |
|  +------------------------+---------------------------------------------+    |
|                                                                               |
+==============================================================================+
```

### Network Device Dangerous Commands

```
+==============================================================================+
|                 NETWORK DEVICE DANGEROUS COMMANDS                             |
+==============================================================================+
|                                                                               |
|  CISCO IOS                                                                    |
|  =========                                                                    |
|                                                                               |
|  +------------------------+---------------------------------------------+    |
|  | Command                | Regex Pattern (case-insensitive)            |    |
|  +------------------------+---------------------------------------------+    |
|  | write erase            | (?i)write\s+erase                           |    |
|  | erase startup-config   | (?i)erase\s+startup-config                  |    |
|  | reload                 | (?i)reload\b                                |    |
|  | configure terminal     | (?i)conf(igure)?\s+t(erminal)?             |    |
|  | no ip route            | (?i)no\s+ip\s+route\s+0\.0\.0\.0           |    |
|  | interface shutdown     | (?i)shutdown\b                              |    |
|  | debug all              | (?i)debug\s+all\b                           |    |
|  | undebug all            | (?i)(undebug|no\s+debug)\s+all              |    |
|  +------------------------+---------------------------------------------+    |
|                                                                               |
|  JUNIPER JUNOS                                                                |
|  =============                                                                |
|                                                                               |
|  +------------------------+---------------------------------------------+    |
|  | Command                | Regex Pattern                               |    |
|  +------------------------+---------------------------------------------+    |
|  | request system halt    | request\s+system\s+halt                     |    |
|  | request system reboot  | request\s+system\s+reboot                   |    |
|  | delete configuration   | delete\s+configuration                      |    |
|  | rollback               | rollback\s+\d+                              |    |
|  | load factory-default   | load\s+factory-default                      |    |
|  +------------------------+---------------------------------------------+    |
|                                                                               |
|  PALO ALTO                                                                    |
|  ==========                                                                   |
|                                                                               |
|  +------------------------+---------------------------------------------+    |
|  | Command                | Regex Pattern                               |    |
|  +------------------------+---------------------------------------------+    |
|  | request restart system | request\s+restart\s+system                  |    |
|  | request shutdown       | request\s+shutdown\s+system                 |    |
|  | delete config          | delete\s+config                             |    |
|  | debug dataplane        | debug\s+dataplane\s+pool                    |    |
|  +------------------------+---------------------------------------------+    |
|                                                                               |
+==============================================================================+
```

### Database Dangerous Commands

```
+==============================================================================+
|                    DATABASE DANGEROUS COMMANDS                                |
+==============================================================================+
|                                                                               |
|  ORACLE                                                                       |
|  ======                                                                       |
|                                                                               |
|  +---------------------------+------------------------------------------+    |
|  | Command                   | Regex Pattern                            |    |
|  +---------------------------+------------------------------------------+    |
|  | DROP TABLE                | (?i)DROP\s+TABLE\b                       |    |
|  | DROP DATABASE             | (?i)DROP\s+DATABASE\b                    |    |
|  | TRUNCATE TABLE            | (?i)TRUNCATE\s+TABLE\b                   |    |
|  | DELETE FROM               | (?i)DELETE\s+FROM\b                      |    |
|  | ALTER USER                | (?i)ALTER\s+USER\b                       |    |
|  | CREATE USER               | (?i)CREATE\s+USER\b                      |    |
|  | GRANT DBA                 | (?i)GRANT\s+DBA\b                        |    |
|  | SHUTDOWN                  | (?i)SHUTDOWN\s+(IMMEDIATE|ABORT)         |    |
|  +---------------------------+------------------------------------------+    |
|                                                                               |
|  POSTGRESQL                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +---------------------------+------------------------------------------+    |
|  | Command                   | Regex Pattern                            |    |
|  +---------------------------+------------------------------------------+    |
|  | DROP DATABASE             | (?i)DROP\s+DATABASE\b                    |    |
|  | DROP TABLE                | (?i)DROP\s+TABLE\b                       |    |
|  | TRUNCATE                  | (?i)TRUNCATE\b                           |    |
|  | DELETE FROM               | (?i)DELETE\s+FROM\b(?!.*WHERE)           |    |
|  | ALTER ROLE                | (?i)ALTER\s+ROLE\b                       |    |
|  | pg_terminate_backend      | (?i)pg_terminate_backend\(               |    |
|  +---------------------------+------------------------------------------+    |
|                                                                               |
|  MYSQL / MARIADB                                                              |
|  ===============                                                              |
|                                                                               |
|  +---------------------------+------------------------------------------+    |
|  | Command                   | Regex Pattern                            |    |
|  +---------------------------+------------------------------------------+    |
|  | DROP DATABASE             | (?i)DROP\s+DATABASE\b                    |    |
|  | DROP TABLE                | (?i)DROP\s+TABLE\b                       |    |
|  | TRUNCATE TABLE            | (?i)TRUNCATE\s+TABLE\b                   |    |
|  | DELETE FROM (no WHERE)    | (?i)DELETE\s+FROM\s+\w+\s*;              |    |
|  | FLUSH PRIVILEGES          | (?i)FLUSH\s+PRIVILEGES\b                 |    |
|  | GRANT ALL                 | (?i)GRANT\s+ALL\b                        |    |
|  | SET GLOBAL                | (?i)SET\s+GLOBAL\b                       |    |
|  +---------------------------+------------------------------------------+    |
|                                                                               |
|  MICROSOFT SQL SERVER                                                         |
|  ====================                                                         |
|                                                                               |
|  +---------------------------+------------------------------------------+    |
|  | Command                   | Regex Pattern                            |    |
|  +---------------------------+------------------------------------------+    |
|  | DROP DATABASE             | (?i)DROP\s+DATABASE\b                    |    |
|  | DROP TABLE                | (?i)DROP\s+TABLE\b                       |    |
|  | TRUNCATE TABLE            | (?i)TRUNCATE\s+TABLE\b                   |    |
|  | xp_cmdshell               | (?i)xp_cmdshell\b                        |    |
|  | sp_configure              | (?i)sp_configure\b                       |    |
|  | SHUTDOWN                  | (?i)SHUTDOWN\b                           |    |
|  | ALTER LOGIN               | (?i)ALTER\s+LOGIN\b                      |    |
|  +---------------------------+------------------------------------------+    |
|                                                                               |
+==============================================================================+
```

---

## Filter Configuration

### Creating Filter Policies

**Via Web Interface:**

1. Navigate to **Configuration** > **Session Policies** > **Command Filters**
2. Click **Add Filter Policy**
3. Configure filter settings

**Via REST API:**

```bash
# Create a new command filter
curl -X POST "https://bastion.company.com/api/v3.12/commandfilters" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "prevent-destructive-commands",
    "description": "Block destructive filesystem and system commands",
    "filter_type": "blacklist",
    "rules": [
        {
            "pattern": "^rm\\s+.*-rf\\s+/",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Recursive force deletion at root level is not permitted"
        },
        {
            "pattern": "^(shutdown|reboot|poweroff|halt)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "System shutdown/reboot requires approval ticket"
        }
    ]
}'
```

### Command Filter Schema

```json
{
    "name": "string (required)",
    "description": "string (optional)",
    "filter_type": "whitelist | blacklist | audit",
    "enabled": true,
    "case_sensitive": true,
    "rules": [
        {
            "id": "integer (auto-generated)",
            "pattern": "string (required)",
            "pattern_type": "exact | contains | wildcard | regex",
            "action": "allow | deny | audit",
            "message": "string (shown to user on deny)",
            "alert": false,
            "alert_severity": "info | warning | high | critical",
            "description": "string (documentation)"
        }
    ],
    "notifications": {
        "email_recipients": ["email@company.com"],
        "syslog_enabled": false,
        "webhook_url": "https://...",
        "dashboard_alert": true
    }
}
```

### Assigning to Authorizations

Command filters are assigned to authorizations to control specific user-target combinations.

```json
{
    "authorization_name": "linux-admins-to-prod",
    "user_group": "Linux-Admins",
    "target_group": "Production-Servers",
    "command_filter": "prevent-destructive-commands",
    "session_policy": {
        "command_filtering_enabled": true,
        "command_filter_policy": "prevent-destructive-commands",
        "filter_log_level": "all"
    }
}
```

**Assignment via REST API:**

```bash
# Assign filter to authorization
curl -X PATCH "https://bastion.company.com/api/v3.12/authorizations/linux-admins-to-prod" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "command_filter": "prevent-destructive-commands"
}'
```

### Priority and Inheritance

```
+==============================================================================+
|                    FILTER PRIORITY AND INHERITANCE                            |
+==============================================================================+
|                                                                               |
|  PRIORITY ORDER (highest to lowest)                                           |
|  ==================================                                           |
|                                                                               |
|  1. Authorization-specific filter (most specific)                            |
|  2. User group default filter                                                |
|  3. Target group default filter                                              |
|  4. Domain default filter                                                    |
|  5. Global default filter (least specific)                                   |
|                                                                               |
|  RULE EVALUATION WITHIN FILTER                                                |
|  =============================                                                |
|                                                                               |
|  * Rules are evaluated in order (rule ID 1, then 2, then 3...)               |
|  * First matching rule wins                                                  |
|  * Place more specific rules before general rules                            |
|                                                                               |
|  COMBINING FILTERS                                                            |
|  =================                                                            |
|                                                                               |
|  When multiple filters apply:                                                |
|                                                                               |
|  +------------------+------------------+------------------+                   |
|  | Filter 1         | Filter 2         | Result           |                   |
|  +------------------+------------------+------------------+                   |
|  | Whitelist ALLOW  | Blacklist DENY   | DENY             |                   |
|  | Whitelist ALLOW  | Blacklist -      | ALLOW            |                   |
|  | Whitelist DENY   | Any              | DENY             |                   |
|  | Blacklist DENY   | Any              | DENY             |                   |
|  | Audit            | Any              | LOG + (allow)    |                   |
|  +------------------+------------------+------------------+                   |
|                                                                               |
|  * DENY from any filter = command blocked                                    |
|  * Audit rules never block, only log                                         |
|                                                                               |
+==============================================================================+
```

---

## Pattern Examples Library

### Prevent System Shutdown/Reboot

```json
{
    "name": "no-shutdown",
    "description": "Prevent system shutdown and reboot commands",
    "filter_type": "blacklist",
    "rules": [
        {
            "pattern": "^(shutdown|poweroff|halt)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "System shutdown is not permitted. Contact operations team."
        },
        {
            "pattern": "^reboot\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Reboot requires maintenance window approval."
        },
        {
            "pattern": "^init\\s+[06]\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Runlevel changes are restricted."
        },
        {
            "pattern": "^telinit\\s+[06]\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Runlevel changes are restricted."
        },
        {
            "pattern": "^systemctl\\s+(poweroff|reboot|halt)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Use ticketing system for system restarts."
        }
    ]
}
```

### Prevent User Management

```json
{
    "name": "no-user-management",
    "description": "Block user and group management commands",
    "filter_type": "blacklist",
    "rules": [
        {
            "pattern": "^useradd\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "User creation must go through identity management."
        },
        {
            "pattern": "^userdel\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "User deletion must go through identity management."
        },
        {
            "pattern": "^usermod\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "User modification must go through identity management."
        },
        {
            "pattern": "^groupadd\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Group creation requires change request."
        },
        {
            "pattern": "^groupdel\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Group deletion requires change request."
        },
        {
            "pattern": "^passwd\\s+(?!-S)",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Password changes must use central password management."
        },
        {
            "pattern": "^chpasswd\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Bulk password changes not permitted."
        },
        {
            "pattern": "^visudo\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Sudoers modification requires change approval."
        }
    ]
}
```

### Prevent File Deletion (rm -rf)

```json
{
    "name": "safe-delete",
    "description": "Prevent dangerous rm commands",
    "filter_type": "blacklist",
    "rules": [
        {
            "pattern": "^rm\\s+.*-rf\\s+/\\s*$",
            "pattern_type": "regex",
            "action": "deny",
            "message": "CRITICAL: Filesystem wipe attempt blocked!"
        },
        {
            "pattern": "^rm\\s+.*-rf\\s+/\\*",
            "pattern_type": "regex",
            "action": "deny",
            "message": "CRITICAL: Root directory deletion blocked!"
        },
        {
            "pattern": "^rm\\s+.*-rf\\s+~",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Home directory recursive deletion blocked."
        },
        {
            "pattern": "^rm\\s+.*-rf\\s+\\.\\.",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Parent directory deletion blocked."
        },
        {
            "pattern": "^rm\\s+.*-rf\\s+\\*\\s*$",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Wildcard recursive deletion blocked. Specify path explicitly."
        },
        {
            "pattern": "^rm\\s+.*-rf\\s+/(etc|var|usr|home|opt|boot)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "System directory deletion blocked."
        }
    ]
}
```

### Prevent Network Changes

```json
{
    "name": "no-network-changes",
    "description": "Block network configuration changes",
    "filter_type": "blacklist",
    "rules": [
        {
            "pattern": "^iptables\\s+-F",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Flushing firewall rules is prohibited."
        },
        {
            "pattern": "^iptables\\s+-X",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Deleting firewall chains is prohibited."
        },
        {
            "pattern": "^ip\\s+route\\s+(add|del|change)",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Route modifications require change approval."
        },
        {
            "pattern": "^route\\s+(add|del)",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Route modifications require change approval."
        },
        {
            "pattern": "^ifconfig\\s+\\w+\\s+down\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Disabling network interfaces is blocked."
        },
        {
            "pattern": "^ip\\s+link\\s+set\\s+\\w+\\s+down\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Disabling network interfaces is blocked."
        },
        {
            "pattern": "^systemctl\\s+(stop|disable)\\s+(network|NetworkManager|sshd|ssh)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Stopping network services is blocked."
        },
        {
            "pattern": "^firewall-cmd\\s+--permanent",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Permanent firewall changes require approval."
        }
    ]
}
```

### Prevent Privilege Escalation

```json
{
    "name": "no-privilege-escalation",
    "description": "Block attempts to escalate privileges",
    "filter_type": "blacklist",
    "rules": [
        {
            "pattern": "chmod\\s+[0-7]*[4-7][0-7]{2}\\s+.*s",
            "pattern_type": "regex",
            "action": "deny",
            "message": "SUID/SGID bit modification blocked."
        },
        {
            "pattern": "chmod\\s+\\+s\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "SUID/SGID bit modification blocked."
        },
        {
            "pattern": "chmod\\s+[ugo]*s",
            "pattern_type": "regex",
            "action": "deny",
            "message": "SUID/SGID bit modification blocked."
        },
        {
            "pattern": "(vi|vim|nano|emacs)\\s+/etc/sudoers\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Direct sudoers editing blocked. Use visudo via change request."
        },
        {
            "pattern": "echo.*>>\\s*/etc/sudoers\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Sudoers modification blocked."
        },
        {
            "pattern": "setcap\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Capability modification requires approval."
        },
        {
            "pattern": "^su\\s+-\\s*$",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Switching to root shell is blocked. Use sudo for specific commands."
        },
        {
            "pattern": "^sudo\\s+su\\s*$",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Root shell via sudo blocked. Use sudo for specific commands."
        }
    ]
}
```

### Allow Read-Only Operations

```json
{
    "name": "read-only-access",
    "description": "Whitelist for read-only system access",
    "filter_type": "whitelist",
    "rules": [
        {
            "pattern": "^ls\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "List files and directories"
        },
        {
            "pattern": "^cat\\s+",
            "pattern_type": "regex",
            "action": "allow",
            "description": "View file contents"
        },
        {
            "pattern": "^less\\s+",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Page through files"
        },
        {
            "pattern": "^more\\s+",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Page through files"
        },
        {
            "pattern": "^head\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "View first lines"
        },
        {
            "pattern": "^tail\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "View last lines"
        },
        {
            "pattern": "^grep\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Search file contents"
        },
        {
            "pattern": "^find\\s+.*-type\\s+f",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Find files"
        },
        {
            "pattern": "^(ps|top|htop)\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "View processes"
        },
        {
            "pattern": "^(df|du|free|uptime|w|who|id|hostname)\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "System information commands"
        },
        {
            "pattern": "^(netstat|ss|ip\\s+a|ip\\s+r)\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Network information (read-only)"
        },
        {
            "pattern": "^history\\b",
            "pattern_type": "regex",
            "action": "allow",
            "description": "View command history"
        },
        {
            "pattern": "^pwd\\s*$",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Print working directory"
        },
        {
            "pattern": "^cd\\s+",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Change directory"
        },
        {
            "pattern": "^exit\\s*$",
            "pattern_type": "regex",
            "action": "allow",
            "description": "Exit session"
        }
    ]
}
```

### Database Query Restrictions

```json
{
    "name": "database-dml-only",
    "description": "Allow only SELECT, INSERT, UPDATE - no DDL or admin commands",
    "filter_type": "blacklist",
    "rules": [
        {
            "pattern": "(?i)DROP\\s+(TABLE|DATABASE|INDEX|VIEW|PROCEDURE|FUNCTION)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "DROP statements require DBA approval."
        },
        {
            "pattern": "(?i)TRUNCATE\\s+TABLE\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "TRUNCATE requires DBA approval."
        },
        {
            "pattern": "(?i)DELETE\\s+FROM\\s+\\w+\\s*;",
            "pattern_type": "regex",
            "action": "deny",
            "message": "DELETE without WHERE clause is not allowed."
        },
        {
            "pattern": "(?i)ALTER\\s+(TABLE|DATABASE|USER|ROLE)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "ALTER statements require DBA approval."
        },
        {
            "pattern": "(?i)CREATE\\s+(TABLE|DATABASE|USER|ROLE|INDEX)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "CREATE statements require DBA approval."
        },
        {
            "pattern": "(?i)GRANT\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "GRANT statements require security approval."
        },
        {
            "pattern": "(?i)REVOKE\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "REVOKE statements require security approval."
        },
        {
            "pattern": "(?i)(SHUTDOWN|KILL\\s+\\d+)\\b",
            "pattern_type": "regex",
            "action": "deny",
            "message": "Database admin commands are blocked."
        }
    ]
}
```

---

## Testing Filters

### How to Test Before Deployment

```
+==============================================================================+
|                        FILTER TESTING WORKFLOW                                |
+==============================================================================+
|                                                                               |
|  STEP 1: Create Test Filter in Audit Mode                                    |
|  ========================================                                     |
|                                                                               |
|  Start with audit-only mode to observe behavior without blocking             |
|                                                                               |
|  {                                                                            |
|      "name": "test-destructive-filter",                                       |
|      "filter_type": "audit",   <-- Audit only, no blocking                   |
|      "rules": [ ... ]                                                        |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  STEP 2: Assign to Test Authorization                                        |
|  ====================================                                         |
|                                                                               |
|  Create test authorization with test user group and non-production targets   |
|                                                                               |
|  {                                                                            |
|      "authorization_name": "filter-testing",                                  |
|      "user_group": "Filter-Test-Users",                                       |
|      "target_group": "Test-Servers",                                          |
|      "command_filter": "test-destructive-filter"                              |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  STEP 3: Execute Test Commands                                               |
|  =============================                                                |
|                                                                               |
|  Run commands that should match and should not match the filter              |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  STEP 4: Review Audit Logs                                                   |
|  =========================                                                    |
|                                                                               |
|  Check which commands were flagged                                           |
|                                                                               |
|  wabadmin audit --filter "command_filter" --last 50                          |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  STEP 5: Convert to Blacklist/Whitelist                                      |
|  ======================================                                       |
|                                                                               |
|  Once patterns are validated, change filter_type to enforce blocking         |
|                                                                               |
+==============================================================================+
```

### Dry-Run Mode

WALLIX Bastion supports a dry-run mode for command filter testing.

```bash
# Test a command against a filter without execution
curl -X POST "https://bastion.company.com/api/v3.12/commandfilters/test" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "filter_name": "prevent-destructive-commands",
    "command": "rm -rf /var/log/oldlogs",
    "context": {
        "user": "testuser",
        "target": "srv-test-01"
    }
}'
```

**Response:**

```json
{
    "command": "rm -rf /var/log/oldlogs",
    "result": "deny",
    "matched_rule": {
        "id": 1,
        "pattern": "^rm\\s+.*-rf\\s+/",
        "pattern_type": "regex"
    },
    "message": "Recursive force deletion at root level is not permitted"
}
```

### Test User Setup

Create a dedicated test user and authorization for filter testing.

```json
{
    "test_setup": {
        "user_group": {
            "name": "Command-Filter-Testers",
            "description": "Users for testing command filter policies",
            "members": ["filter-tester-01", "filter-tester-02"]
        },
        "target_group": {
            "name": "Filter-Test-Targets",
            "description": "Non-production targets for filter testing",
            "targets": ["test-server-01", "test-server-02"]
        },
        "authorization": {
            "name": "filter-testing-auth",
            "user_group": "Command-Filter-Testers",
            "target_group": "Filter-Test-Targets",
            "is_recorded": true,
            "command_filter": "test-filter-policy"
        }
    }
}
```

### Filter Test Checklist

```
+==============================================================================+
|                       FILTER TEST CHECKLIST                                   |
+==============================================================================+
|                                                                               |
|  [ ] Create filter in audit mode first                                       |
|  [ ] Assign to test authorization only                                       |
|  [ ] Test with non-production targets                                        |
|  [ ] Verify expected commands are matched                                    |
|  [ ] Verify legitimate commands are NOT matched                              |
|  [ ] Test edge cases:                                                        |
|      [ ] Commands with extra whitespace                                      |
|      [ ] Commands with different argument order                              |
|      [ ] Commands with full paths (/usr/bin/rm vs rm)                        |
|      [ ] Commands with environment variables                                 |
|      [ ] Commands using aliases (if applicable)                              |
|  [ ] Review audit logs for false positives/negatives                         |
|  [ ] Document any pattern adjustments needed                                 |
|  [ ] Convert to blacklist/whitelist after validation                         |
|  [ ] Test in production with limited user group first                        |
|  [ ] Monitor for user-reported issues                                        |
|  [ ] Roll out to full user population                                        |
|                                                                               |
+==============================================================================+
```

---

## Handling Complex Commands

### Piped Commands

```
+==============================================================================+
|                       PIPED COMMAND HANDLING                                  |
+==============================================================================+
|                                                                               |
|  BEHAVIOR                                                                     |
|  ========                                                                     |
|                                                                               |
|  Piped commands are evaluated as a single string by default.                 |
|  Each command in the pipe can be evaluated separately with configuration.    |
|                                                                               |
|  EXAMPLE: cat /etc/passwd | grep root | wc -l                                |
|                                                                               |
|  DEFAULT MODE (whole command)                                                 |
|  ----------------------------                                                 |
|  Pattern: "cat /etc/passwd"                                                  |
|  Result: MATCHES (substring found)                                           |
|                                                                               |
|  SPLIT MODE (each component)                                                 |
|  ---------------------------                                                  |
|  Session policy: "split_piped_commands": true                                |
|                                                                               |
|  Evaluates:                                                                  |
|    1. cat /etc/passwd                                                        |
|    2. grep root                                                              |
|    3. wc -l                                                                  |
|                                                                               |
|  Any deny = entire command blocked                                           |
|                                                                               |
|  CONFIGURATION                                                                |
|  =============                                                                |
|                                                                               |
|  {                                                                            |
|      "session_policy": {                                                      |
|          "command_filtering": {                                               |
|              "split_piped_commands": true,                                    |
|              "split_semicolon_commands": true,                                |
|              "split_and_or_commands": true                                    |
|          }                                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Command Substitution

```
+==============================================================================+
|                    COMMAND SUBSTITUTION HANDLING                              |
+==============================================================================+
|                                                                               |
|  CHALLENGE                                                                    |
|  =========                                                                    |
|                                                                               |
|  Command substitution executes before the main command:                      |
|                                                                               |
|    rm -rf $(cat files_to_delete.txt)                                         |
|    rm -rf `cat files_to_delete.txt`                                          |
|                                                                               |
|  The inner command runs first, returning output to rm.                       |
|                                                                               |
|  DETECTION PATTERNS                                                           |
|  ==================                                                           |
|                                                                               |
|  Block dangerous commands with substitution:                                 |
|                                                                               |
|  {                                                                            |
|      "pattern": "rm\\s+.*-rf\\s+.*\\$\\(",                                   |
|      "pattern_type": "regex",                                                 |
|      "action": "deny",                                                        |
|      "message": "rm -rf with command substitution is blocked"                |
|  }                                                                            |
|                                                                               |
|  {                                                                            |
|      "pattern": "rm\\s+.*-rf\\s+.*`",                                        |
|      "pattern_type": "regex",                                                 |
|      "action": "deny",                                                        |
|      "message": "rm -rf with backtick substitution is blocked"               |
|  }                                                                            |
|                                                                               |
|  LIMITATIONS                                                                  |
|  ===========                                                                  |
|                                                                               |
|  * Cannot prevent inner command from executing                               |
|  * Filter sees literal $(command) string, not output                         |
|  * Consider blocking all command substitution for high-security              |
|                                                                               |
|  BLOCK ALL SUBSTITUTION (HIGH SECURITY)                                       |
|  ======================================                                       |
|                                                                               |
|  {                                                                            |
|      "pattern": "(\\$\\(|`)",                                                 |
|      "pattern_type": "regex",                                                 |
|      "action": "deny",                                                        |
|      "message": "Command substitution is not permitted on this system"       |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Encoded Commands

```
+==============================================================================+
|                      ENCODED COMMAND HANDLING                                 |
+==============================================================================+
|                                                                               |
|  COMMON EVASION TECHNIQUES                                                    |
|  =========================                                                    |
|                                                                               |
|  BASE64 ENCODING                                                              |
|  ---------------                                                              |
|                                                                               |
|  Attacker may try:                                                           |
|    echo "cm0gLXJmIC8=" | base64 -d | bash                                    |
|    (decodes to "rm -rf /")                                                   |
|                                                                               |
|  DETECTION PATTERN:                                                           |
|  {                                                                            |
|      "pattern": "base64\\s+-d.*\\|.*bash",                                   |
|      "pattern_type": "regex",                                                 |
|      "action": "deny",                                                        |
|      "message": "Base64 decoded command execution is blocked"                |
|  }                                                                            |
|                                                                               |
|  HEX ENCODING                                                                 |
|  ------------                                                                 |
|                                                                               |
|  Attacker may try:                                                           |
|    echo -e "\x72\x6d\x20\x2d\x72\x66\x20\x2f" | bash                         |
|                                                                               |
|  DETECTION PATTERN:                                                           |
|  {                                                                            |
|      "pattern": "echo\\s+-e\\s+.*\\\\x.*\\|.*bash",                          |
|      "pattern_type": "regex",                                                 |
|      "action": "deny"                                                         |
|  }                                                                            |
|                                                                               |
|  VARIABLE OBFUSCATION                                                         |
|  --------------------                                                         |
|                                                                               |
|  a="rm"; b="-rf"; c="/"; $a $b $c                                            |
|                                                                               |
|  LIMITATION: Cannot be prevented by command filtering                        |
|  MITIGATION: Use application whitelisting on target                          |
|                                                                               |
|  POWERSHELL ENCODED                                                           |
|  ==================                                                           |
|                                                                               |
|  powershell -EncodedCommand <base64>                                         |
|                                                                               |
|  DETECTION PATTERN:                                                           |
|  {                                                                            |
|      "pattern": "(?i)powershell.*-enc(odedcommand)?\\s+",                    |
|      "pattern_type": "regex",                                                 |
|      "action": "deny",                                                        |
|      "message": "Encoded PowerShell commands are blocked"                    |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Multi-Line Commands

```
+==============================================================================+
|                     MULTI-LINE COMMAND HANDLING                               |
+==============================================================================+
|                                                                               |
|  BEHAVIOR                                                                     |
|  ========                                                                     |
|                                                                               |
|  Multi-line commands (using backslash continuation) are buffered and         |
|  evaluated as a single logical command.                                      |
|                                                                               |
|  EXAMPLE:                                                                     |
|                                                                               |
|  rm \                                                                         |
|    -rf \                                                                      |
|    /var/log/*                                                                |
|                                                                               |
|  EVALUATED AS: "rm -rf /var/log/*"                                           |
|                                                                               |
|  HERE DOCUMENTS                                                               |
|  ==============                                                               |
|                                                                               |
|  cat << EOF                                                                  |
|  rm -rf /                                                                    |
|  EOF                                                                          |
|                                                                               |
|  The heredoc content is passed as stdin, not as a command.                   |
|  Filter evaluates only: "cat << EOF"                                         |
|                                                                               |
|  DETECTION PATTERN (block heredoc to dangerous commands):                    |
|                                                                               |
|  {                                                                            |
|      "pattern": "(bash|sh|zsh)\\s*<<",                                       |
|      "pattern_type": "regex",                                                 |
|      "action": "deny",                                                        |
|      "message": "Heredoc to shell is blocked"                                |
|  }                                                                            |
|                                                                               |
|  CONFIGURATION                                                                |
|  =============                                                                |
|                                                                               |
|  {                                                                            |
|      "session_policy": {                                                      |
|          "command_filtering": {                                               |
|              "multiline_continuation": true,                                  |
|              "max_command_length": 4096                                       |
|          }                                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

---

## User Notification

### Custom Rejection Messages

Configure user-friendly messages for blocked commands.

```json
{
    "filter_name": "production-restrictions",
    "rules": [
        {
            "pattern": "^reboot\\b",
            "action": "deny",
            "message": "System reboot blocked.\n\nTo reboot this system:\n1. Create change request in ServiceNow\n2. Get manager approval\n3. Contact operations team at ext. 4500\n\nRef: Policy SEC-001"
        },
        {
            "pattern": "^rm\\s+.*-rf\\s+/",
            "action": "deny",
            "message": "SECURITY ALERT: Destructive command blocked.\n\nThis action has been logged and security team notified.\nIncident ID: {{incident_id}}"
        }
    ]
}
```

### Message Variables

| Variable | Description |
|----------|-------------|
| `{{user}}` | Current user name |
| `{{target}}` | Target system name |
| `{{command}}` | Blocked command |
| `{{timestamp}}` | Current timestamp |
| `{{session_id}}` | Session identifier |
| `{{incident_id}}` | Auto-generated incident ID |
| `{{filter_name}}` | Filter that blocked command |
| `{{rule_id}}` | Specific rule that matched |

### What Users See

```
+==============================================================================+
|                      USER EXPERIENCE ON BLOCK                                 |
+==============================================================================+
|                                                                               |
|  TERMINAL OUTPUT (SSH/Telnet)                                                 |
|  ============================                                                 |
|                                                                               |
|  user@target:~$ rm -rf /var/log/*                                            |
|                                                                               |
|  ┌─────────────────────────────────────────────────────────────────────┐     |
|  │ WALLIX COMMAND BLOCKED                                                │     |
|  ├─────────────────────────────────────────────────────────────────────┤     |
|  │                                                                       │     |
|  │ The command you entered has been blocked by security policy.         │     |
|  │                                                                       │     |
|  │ Command:  rm -rf /var/log/*                                          │     |
|  │ Reason:   Recursive force deletion blocked                           │     |
|  │ Policy:   production-restrictions (Rule #3)                          │     |
|  │                                                                       │     |
|  │ To request an exception, contact security@company.com                │     |
|  │                                                                       │     |
|  │ Session ID: SES-2024-001-XYZ                                         │     |
|  │ Timestamp:  2024-01-15 14:32:18 UTC                                   │     |
|  │                                                                       │     |
|  └─────────────────────────────────────────────────────────────────────┘     |
|                                                                               |
|  user@target:~$ _                                                            |
|                                                                               |
+==============================================================================+
```

### Alerting on Blocked Commands

```json
{
    "filter_name": "critical-protection",
    "alert_config": {
        "on_block": {
            "email": {
                "enabled": true,
                "recipients": ["security@company.com", "soc@company.com"],
                "template": "command_blocked_alert",
                "include_command": true,
                "include_session_context": true
            },
            "syslog": {
                "enabled": true,
                "facility": "auth",
                "severity": "warning",
                "format": "CEF"
            },
            "webhook": {
                "enabled": true,
                "url": "https://siem.company.com/api/alerts",
                "method": "POST",
                "headers": {
                    "Authorization": "Bearer ${WEBHOOK_TOKEN}"
                }
            },
            "sms": {
                "enabled": false,
                "recipients": ["+1-555-0100"]
            }
        },
        "severity_escalation": {
            "critical_patterns": ["rm -rf /", "dd if=/dev/zero"],
            "escalation_action": "page_oncall"
        }
    }
}
```

---

## Audit and Reporting

### Blocked Command Logs

All blocked commands are logged with full context.

```
+==============================================================================+
|                      BLOCKED COMMAND LOG ENTRY                                |
+==============================================================================+
|                                                                               |
|  {                                                                            |
|      "timestamp": "2024-01-15T14:32:18.456Z",                                |
|      "event_type": "COMMAND_BLOCKED",                                         |
|      "session_id": "SES-2024-001-ABC123",                                     |
|      "user": {                                                                |
|          "name": "jsmith",                                                    |
|          "ip": "10.0.1.50",                                                   |
|          "groups": ["Linux-Admins"]                                           |
|      },                                                                        |
|      "target": {                                                              |
|          "name": "srv-prod-01",                                               |
|          "ip": "192.168.1.100",                                               |
|          "account": "root"                                                    |
|      },                                                                        |
|      "command": {                                                             |
|          "original": "rm -rf /var/log/*",                                     |
|          "parsed": {                                                          |
|              "executable": "rm",                                              |
|              "arguments": ["-rf", "/var/log/*"]                               |
|          }                                                                    |
|      },                                                                        |
|      "filter": {                                                              |
|          "name": "prevent-destructive-commands",                              |
|          "rule_id": 3,                                                        |
|          "pattern": "^rm\\s+.*-rf\\s+/",                                      |
|          "pattern_type": "regex",                                             |
|          "action": "deny"                                                     |
|      },                                                                        |
|      "authorization": "linux-admins-to-prod"                                  |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Viewing Blocked Commands

**Via CLI:**

```bash
# View recent blocked commands
wabadmin audit --filter "event_type=COMMAND_BLOCKED" --last 50

# View blocked commands for specific user
wabadmin audit --filter "event_type=COMMAND_BLOCKED,user=jsmith" --last 20

# View blocked commands for specific filter
wabadmin audit --filter "filter_name=prevent-destructive" --last 20

# Export to CSV
wabadmin audit --filter "event_type=COMMAND_BLOCKED" --format csv > blocked.csv
```

**Via REST API:**

```bash
# Query blocked commands
curl -X GET "https://bastion.company.com/api/v3.12/audit/events" \
  -H "Authorization: Bearer ${TOKEN}" \
  -G \
  --data-urlencode "filter=event_type eq 'COMMAND_BLOCKED'" \
  --data-urlencode "from=2024-01-01T00:00:00Z" \
  --data-urlencode "to=2024-01-31T23:59:59Z" \
  --data-urlencode "limit=100"
```

### Compliance Reporting

```
+==============================================================================+
|                      COMPLIANCE REPORTS                                       |
+==============================================================================+
|                                                                               |
|  AVAILABLE REPORTS                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------------------------+-----------------------------------+   |
|  | Report Name                       | Description                       |   |
|  +-----------------------------------+-----------------------------------+   |
|  | Command Filter Summary            | Overview of filter activity       |   |
|  | Blocked Commands by User          | User-wise blocking statistics     |   |
|  | Blocked Commands by Target        | Target-wise blocking statistics   |   |
|  | Filter Policy Effectiveness       | Match rates and false positives   |   |
|  | Pattern Coverage Analysis         | Commands not matching any rule    |   |
|  | Audit-Only Findings               | Commands flagged but allowed      |   |
|  | Privilege Escalation Attempts     | Security-focused report           |   |
|  +-----------------------------------+-----------------------------------+   |
|                                                                               |
|  SAMPLE REPORT OUTPUT                                                         |
|  ====================                                                         |
|                                                                               |
|  Command Filter Summary Report                                               |
|  Period: 2024-01-01 to 2024-01-31                                            |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |                    EXECUTIVE SUMMARY                               |       |
|  +-------------------------------------------------------------------+       |
|  | Total Commands Evaluated     | 45,678                              |       |
|  | Commands Blocked             | 234 (0.51%)                         |       |
|  | Commands Audited             | 1,567 (3.43%)                       |       |
|  | Commands Allowed             | 43,877 (96.06%)                     |       |
|  | Unique Users Blocked         | 12                                  |       |
|  | Unique Targets Affected      | 28                                  |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  TOP BLOCKED COMMANDS                                                         |
|  --------------------                                                         |
|                                                                               |
|  1. rm -rf /var/log/*          (45 blocks)                                   |
|  2. shutdown -h now            (32 blocks)                                   |
|  3. iptables -F                (28 blocks)                                   |
|  4. passwd root                (21 blocks)                                   |
|  5. visudo                     (18 blocks)                                   |
|                                                                               |
+==============================================================================+
```

### SIEM Integration Events

```
+==============================================================================+
|                        SIEM EVENT FORMAT                                      |
+==============================================================================+
|                                                                               |
|  CEF FORMAT                                                                   |
|  ==========                                                                   |
|                                                                               |
|  CEF:0|WALLIX|Bastion|12.1|201|Command Blocked|7|                            |
|  src=10.0.1.50 suser=jsmith dhost=srv-prod-01 duser=root                     |
|  cs1=prevent-destructive-commands cs1Label=FilterName                         |
|  cs2=rm -rf /var/log/* cs2Label=BlockedCommand                               |
|  cs3=SES-2024-001-ABC123 cs3Label=SessionID                                  |
|  rt=Jan 15 2024 14:32:18 cat=Security                                        |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  JSON FORMAT (for Splunk/ELK)                                                 |
|  ============================                                                 |
|                                                                               |
|  {                                                                            |
|      "vendor": "WALLIX",                                                      |
|      "product": "Bastion",                                                    |
|      "version": "12.1",                                                       |
|      "event_id": 201,                                                         |
|      "event_name": "Command Blocked",                                         |
|      "severity": 7,                                                           |
|      "source_ip": "10.0.1.50",                                               |
|      "source_user": "jsmith",                                                 |
|      "destination_host": "srv-prod-01",                                       |
|      "destination_user": "root",                                              |
|      "filter_name": "prevent-destructive-commands",                           |
|      "blocked_command": "rm -rf /var/log/*",                                  |
|      "session_id": "SES-2024-001-ABC123",                                     |
|      "timestamp": "2024-01-15T14:32:18Z"                                      |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

---

## Troubleshooting

### Filter Not Matching

```
+==============================================================================+
|                    TROUBLESHOOTING: FILTER NOT MATCHING                       |
+==============================================================================+
|                                                                               |
|  SYMPTOM: Command should be blocked but is allowed                           |
|                                                                               |
|  DIAGNOSTIC STEPS                                                             |
|  ================                                                             |
|                                                                               |
|  1. Verify filter is enabled                                                 |
|     -----------------------                                                   |
|     curl -X GET ".../api/v3.12/commandfilters/my-filter" | jq '.enabled'     |
|                                                                               |
|  2. Verify filter is assigned to authorization                               |
|     ------------------------------------------                                |
|     curl -X GET ".../api/v3.12/authorizations/my-auth" | jq '.command_filter'|
|                                                                               |
|  3. Test pattern match                                                       |
|     ------------------                                                        |
|     curl -X POST ".../api/v3.12/commandfilters/test" -d '{                   |
|         "filter_name": "my-filter",                                          |
|         "command": "exact command that was typed"                            |
|     }'                                                                        |
|                                                                               |
|  4. Check for whitespace issues                                              |
|     ---------------------------                                               |
|     Pattern: "rm -rf /"                                                       |
|     Command: "rm  -rf /"  (extra space)                                      |
|     Fix: "rm\\s+-rf\\s+/"  (use \s+ for flexible spacing)                    |
|                                                                               |
|  5. Check for path differences                                               |
|     --------------------------                                                |
|     Pattern: "rm"                                                             |
|     Command: "/usr/bin/rm"  (full path)                                      |
|     Fix: "(^|/)rm\\b"  (match rm anywhere)                                   |
|                                                                               |
|  6. Check case sensitivity                                                   |
|     ----------------------                                                    |
|     Pattern: "SHUTDOWN" (uppercase)                                          |
|     Command: "shutdown" (lowercase)                                          |
|     Fix: "(?i)shutdown" or "case_sensitive": false                          |
|                                                                               |
|  7. Check rule order                                                         |
|     ----------------                                                          |
|     Earlier ALLOW rule may match before DENY rule                            |
|     Move DENY rules higher or make patterns more specific                    |
|                                                                               |
+==============================================================================+
```

### False Positives

```
+==============================================================================+
|                    TROUBLESHOOTING: FALSE POSITIVES                           |
+==============================================================================+
|                                                                               |
|  SYMPTOM: Legitimate command is blocked                                      |
|                                                                               |
|  COMMON CAUSES                                                                |
|  =============                                                                |
|                                                                               |
|  1. Pattern too broad                                                        |
|     -----------------                                                         |
|     Pattern: "rm"                                                             |
|     Blocks: "rm file.txt" (intended)                                         |
|             "chmod" (unintended - contains "rm")                             |
|                                                                               |
|     Fix: Use word boundaries                                                 |
|     Better: "\\brm\\b" or "^rm\\s+"                                          |
|                                                                               |
|  2. Substring matching                                                       |
|     -------------------                                                       |
|     Pattern: "drop"                                                          |
|     Blocks: "DROP TABLE" (intended)                                          |
|             "dropdown" (unintended)                                          |
|                                                                               |
|     Fix: Add context                                                         |
|     Better: "(?i)DROP\\s+(TABLE|DATABASE)\\b"                                |
|                                                                               |
|  3. Missing exclusions                                                       |
|     -------------------                                                       |
|     Pattern: "passwd"                                                        |
|     Blocks: "passwd user" (intended)                                         |
|             "cat /etc/passwd" (maybe unintended)                             |
|             "passwd -S" (status check - unintended)                          |
|                                                                               |
|     Fix: Add exceptions                                                      |
|     Better: "^passwd\\s+(?!-S)" (negative lookahead)                        |
|                                                                               |
|  RESOLUTION PROCESS                                                           |
|  ==================                                                           |
|                                                                               |
|  1. Identify blocked command from logs                                       |
|  2. Determine which rule matched                                             |
|  3. Analyze why the match occurred                                           |
|  4. Refine pattern to be more specific                                       |
|  5. Test new pattern against false positive case                             |
|  6. Verify original blocking case still works                                |
|  7. Deploy updated filter                                                    |
|                                                                               |
+==============================================================================+
```

### Performance Impact

```
+==============================================================================+
|                    TROUBLESHOOTING: PERFORMANCE IMPACT                        |
+==============================================================================+
|                                                                               |
|  SYMPTOM: Session latency increased after enabling filters                   |
|                                                                               |
|  EXPECTED OVERHEAD                                                            |
|  =================                                                            |
|                                                                               |
|  +--------------------+------------------------+                              |
|  | Pattern Type       | Typical Latency Added  |                              |
|  +--------------------+------------------------+                              |
|  | Exact match        | < 0.1 ms              |                              |
|  | Contains           | 0.1 - 0.5 ms          |                              |
|  | Wildcard           | 0.5 - 1 ms            |                              |
|  | Simple regex       | 1 - 2 ms              |                              |
|  | Complex regex      | 2 - 10 ms             |                              |
|  +--------------------+------------------------+                              |
|                                                                               |
|  Typical total: 2-5 ms per command (acceptable)                              |
|  Concern threshold: > 50 ms per command                                       |
|                                                                               |
|  OPTIMIZATION STRATEGIES                                                      |
|  =======================                                                      |
|                                                                               |
|  1. Reduce number of regex rules                                             |
|     Use exact/contains where possible                                        |
|                                                                               |
|  2. Optimize regex patterns                                                  |
|     BAD:  ".*rm.*-rf.*"  (catastrophic backtracking)                        |
|     GOOD: "^rm\s+-rf\s+"  (anchored, specific)                              |
|                                                                               |
|  3. Order rules by frequency                                                 |
|     Put most commonly matched rules first                                    |
|     Put rarely matched rules last                                            |
|                                                                               |
|  4. Use compiled patterns                                                    |
|     Enable pattern pre-compilation in settings                               |
|                                                                               |
|  5. Reduce audit-all patterns                                                |
|     ".*" matches everything but is expensive                                |
|                                                                               |
|  MONITORING                                                                   |
|  ==========                                                                   |
|                                                                               |
|  # Check filter evaluation time                                              |
|  wabadmin stats --filter-performance                                         |
|                                                                               |
|  # Enable debug logging for investigation                                    |
|  wabadmin config set session.command_filter.debug_logging true               |
|                                                                               |
+==============================================================================+
```

---

## Best Practices

### Start Permissive, Tighten Gradually

```
+==============================================================================+
|                    BEST PRACTICE: GRADUAL ROLLOUT                             |
+==============================================================================+
|                                                                               |
|  PHASE 1: DISCOVERY (2-4 weeks)                                              |
|  ==============================                                               |
|                                                                               |
|  * Deploy filters in AUDIT-ONLY mode                                         |
|  * Collect data on actual command usage                                      |
|  * Identify false positive candidates                                        |
|  * Understand normal user behavior                                           |
|                                                                               |
|  PHASE 2: PILOT (2 weeks)                                                    |
|  ========================                                                     |
|                                                                               |
|  * Enable blocking for small pilot group                                     |
|  * Use volunteer users who understand testing                                |
|  * Rapid feedback loop for issues                                            |
|  * Refine patterns based on real-world feedback                              |
|                                                                               |
|  PHASE 3: STAGED ROLLOUT (2-4 weeks)                                         |
|  ===================================                                          |
|                                                                               |
|  * Expand to larger groups gradually                                         |
|  * 10% -> 25% -> 50% -> 100% deployment                                      |
|  * Monitor support tickets for filter issues                                 |
|  * Maintain easy rollback capability                                         |
|                                                                               |
|  PHASE 4: PRODUCTION (ongoing)                                               |
|  =============================                                                |
|                                                                               |
|  * Full deployment with monitoring                                           |
|  * Regular pattern review (quarterly)                                        |
|  * Exception process for legitimate needs                                    |
|  * Continuous improvement based on incidents                                 |
|                                                                               |
+==============================================================================+
```

### Testing Procedures

```
+==============================================================================+
|                    BEST PRACTICE: TESTING PROCEDURES                          |
+==============================================================================+
|                                                                               |
|  PRE-DEPLOYMENT TESTING                                                       |
|  ======================                                                       |
|                                                                               |
|  1. Unit test each pattern individually                                      |
|     * Test commands that SHOULD match                                        |
|     * Test commands that should NOT match                                    |
|     * Test edge cases (whitespace, paths, case)                              |
|                                                                               |
|  2. Integration test complete filter                                         |
|     * Apply to test authorization                                            |
|     * Connect as test user                                                   |
|     * Execute test command set                                               |
|     * Verify expected blocks and allows                                      |
|                                                                               |
|  3. Regression test with updates                                             |
|     * Document baseline behavior                                             |
|     * After changes, re-run full test suite                                  |
|     * Compare results to baseline                                            |
|                                                                               |
|  TEST CASE TEMPLATE                                                           |
|  ==================                                                           |
|                                                                               |
|  +--------+---------------------------+----------+----------+----------+     |
|  | Test # | Command                   | Expected | Actual   | Status   |     |
|  +--------+---------------------------+----------+----------+----------+     |
|  | 001    | rm -rf /                  | BLOCK    |          |          |     |
|  | 002    | rm -rf /tmp/test          | ALLOW    |          |          |     |
|  | 003    | rm file.txt               | ALLOW    |          |          |     |
|  | 004    | shutdown -h now           | BLOCK    |          |          |     |
|  | 005    | ls -la                    | ALLOW    |          |          |     |
|  +--------+---------------------------+----------+----------+----------+     |
|                                                                               |
+==============================================================================+
```

### Documentation Requirements

```
+==============================================================================+
|                    BEST PRACTICE: DOCUMENTATION                               |
+==============================================================================+
|                                                                               |
|  FOR EACH FILTER POLICY                                                       |
|  ======================                                                       |
|                                                                               |
|  * Purpose and business justification                                        |
|  * Target user groups and authorizations                                     |
|  * Rule descriptions (why each rule exists)                                  |
|  * Known limitations and edge cases                                          |
|  * Exception request process                                                 |
|  * Review schedule and owner                                                 |
|                                                                               |
|  FOR EACH RULE                                                                |
|  =============                                                                |
|                                                                               |
|  * Plain-English description of what it blocks                               |
|  * Regex explanation (if complex)                                            |
|  * Examples of matching commands                                             |
|  * Examples of non-matching commands                                         |
|  * Reason for blocking                                                       |
|  * Compliance reference (if applicable)                                      |
|                                                                               |
|  SAMPLE DOCUMENTATION                                                         |
|  ====================                                                         |
|                                                                               |
|  ## Filter: prevent-filesystem-destruction                                   |
|                                                                               |
|  **Purpose:** Protect production systems from accidental data loss           |
|                                                                               |
|  **Applies To:** All production server authorizations                        |
|                                                                               |
|  **Rules:**                                                                   |
|                                                                               |
|  | ID | Pattern | Blocks | Allows | Compliance |                             |
|  |----|---------|--------|--------|------------|                             |
|  | 1  | rm -rf / | rm -rf /, rm -rf /* | rm -rf /tmp/old | SOC2-CC6.1 |      |
|  | 2  | mkfs | mkfs.ext4 /dev/sda | (none allowed) | SOC2-CC6.1 |            |
|                                                                               |
|  **Exceptions:** Contact security@company.com with change ticket             |
|                                                                               |
|  **Review:** Quarterly by Security Operations                                |
|                                                                               |
+==============================================================================+
```

### Operational Recommendations

```
+==============================================================================+
|                 BEST PRACTICE: OPERATIONAL RECOMMENDATIONS                    |
+==============================================================================+
|                                                                               |
|  DO                                                                           |
|  ==                                                                           |
|                                                                               |
|  * Use specific, anchored patterns (^command\b)                              |
|  * Prefer blacklists for general use (less restrictive)                      |
|  * Use whitelists only for highly restricted access                          |
|  * Include helpful error messages for blocked commands                       |
|  * Test patterns with actual command variations                              |
|  * Document the business reason for each rule                                |
|  * Review filter effectiveness quarterly                                     |
|  * Monitor for user complaints about false positives                         |
|  * Have an exception process for legitimate needs                            |
|  * Keep audit-only rules for sensitive commands                              |
|                                                                               |
|  DON'T                                                                        |
|  =====                                                                        |
|                                                                               |
|  * Use broad patterns like ".*rm.*" (too many false positives)              |
|  * Block without providing alternative/process                               |
|  * Deploy to production without testing                                      |
|  * Ignore user feedback about blocked commands                               |
|  * Create complex regex without documentation                                |
|  * Assume all evasion techniques are covered                                 |
|  * Rely solely on command filtering for security                             |
|                                                                               |
|  COMPLEMENTARY CONTROLS                                                       |
|  ======================                                                       |
|                                                                               |
|  Command filtering should be ONE layer of defense:                           |
|                                                                               |
|  * Session recording (evidence even if filter bypassed)                      |
|  * Real-time monitoring (human oversight)                                    |
|  * Approval workflows (pre-authorization for risky actions)                  |
|  * Just-in-time access (time-limited privileges)                             |
|  * Target hardening (SELinux, AppArmor on target systems)                   |
|                                                                               |
+==============================================================================+
```

---

## Quick Reference

### Common Regex Patterns

| Purpose | Pattern |
|---------|---------|
| Match start of line | `^command` |
| Match end of line | `command$` |
| Word boundary | `\bcommand\b` |
| Any whitespace | `\s+` |
| Optional whitespace | `\s*` |
| Case insensitive | `(?i)command` |
| Alternatives | `(cmd1\|cmd2\|cmd3)` |
| Negative lookahead | `cmd(?!-safe)` |
| Any character | `.` |
| Zero or more | `.*` |
| One or more | `.+` |

### Filter Configuration Checklist

```
[ ] Filter name is descriptive
[ ] Filter type (whitelist/blacklist/audit) is appropriate
[ ] Each rule has clear description
[ ] Patterns use word boundaries where needed
[ ] Case sensitivity is correct for target OS
[ ] User-facing messages are helpful
[ ] Alerting is configured for critical rules
[ ] Filter is assigned to correct authorizations
[ ] Testing completed in non-production
[ ] Documentation is complete
[ ] Exception process is defined
[ ] Review schedule is set
```

---

## Related Documentation

- [06 - Authorization & Access Control](../07-authorization/README.md)
- [08 - Session Management](../09-session-management/README.md)
- [26 - API Reference](../17-api-reference/README.md)
- [32 - Incident Response](../23-incident-response/README.md)
- [33 - Compliance Audit](../24-compliance-audit/README.md)

## External Resources

- WALLIX Documentation Portal: https://pam.wallix.one/documentation
- REST API Reference: https://github.com/wallix/wbrest_samples
- Regular Expression Reference: https://www.regular-expressions.info/

---

## See Also

**Related Sections:**
- [09 - Session Management](../09-session-management/README.md) - Session recording and monitoring
- [07 - Authorization](../07-authorization/README.md) - Access control policies

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [50 - File Transfer Policies](../50-file-transfer/README.md) for controlling SCP/SFTP file transfers.
