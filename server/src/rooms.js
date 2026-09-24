// In-memory room manager for DevArena Live

const rooms = new Map();

export const DEFAULT_PROBLEM = {
  title: "Palindrome Verification",
  description: "Write a function to check if a string is a palindrome. Handle empty strings and make sure comparison is case-insensitive, ignoring whitespace.",
  starterCode: {
    python: `def is_palindrome(s: str) -> bool:
    """Check if string is palindrome (case-insensitive & ignoring spaces)"""
    clean = ''.join(c.lower() for c in s if c.isalnum())
    return clean == clean[::-1]

# Test cases
tests = [
    ("racecar", True),
    ("hello", False),
    ("A man a plan a canal Panama", True),
    ("", True),
    ("Was it a car or a cat I saw", True),
]

for text, expected in tests:
    result = is_palindrome(text)
    status = "✅ PASS" if result == expected else "❌ FAIL"
    print(f"{status} | is_palindrome({repr(text)}) => {result}")
`,
    javascript: `function isPalindrome(s) {
  const clean = s.toLowerCase().replace(/[^a-z0-9]/g, '');
  return clean === clean.split('').reverse().join('');
}

// Test cases
const tests = [
  ["racecar", true],
  ["hello", false],
  ["A man a plan a canal Panama", true],
  ["", true],
  ["Was it a car or a cat I saw", true]
];

tests.forEach(([text, expected]) => {
  const result = isPalindrome(text);
  const status = result === expected ? "✅ PASS" : "❌ FAIL";
  console.log(\`\${status} | isPalindrome("\${text}") => \${result}\`);
});
`,
    typescript: `function isPalindrome(s: string): boolean {
  const clean = s.toLowerCase().replace(/[^a-z0-9]/g, '');
  return clean === clean.split('').reverse().join('');
}

const tests: [string, boolean][] = [
  ["racecar", true],
  ["hello", false],
  ["A man a plan a canal Panama", true],
  ["", true]
];

tests.forEach(([text, expected]) => {
  const result = isPalindrome(text);
  const status = result === expected ? "✅ PASS" : "❌ FAIL";
  console.log(\`\${status} | isPalindrome("\${text}") => \${result}\`);
});
`,
    cpp: `#include <iostream>
#include <string>
#include <algorithm>
#include <cctype>
#include <vector>

using namespace std;

bool isPalindrome(string s) {
    string clean = "";
    for (char c : s) {
        if (isalnum(c)) clean += tolower(c);
    }
    string rev = clean;
    reverse(rev.begin(), rev.end());
    return clean == rev;
}

int main() {
    vector<pair<string, bool>> tests = {
        {"racecar", true},
        {"hello", false},
        {"A man a plan a canal Panama", true},
        {"", true}
    };

    for (const auto& [text, expected] : tests) {
        bool res = isPalindrome(text);
        string status = (res == expected) ? "✅ PASS" : "❌ FAIL";
        cout << status << " | isPalindrome(\\"" << text << "\\") => " << (res ? "true" : "false") << "\\n";
    }
    return 0;
}
`,
    java: `import java.util.*;

public class Solution {
    public static boolean isPalindrome(String s) {
        StringBuilder clean = new StringBuilder();
        for (char c : s.toCharArray()) {
            if (Character.isLetterOrDigit(c)) {
                clean.append(Character.toLowerCase(c));
            }
        }
        String orig = clean.toString();
        String rev = clean.reverse().toString();
        return orig.equals(rev);
    }

    public static void main(String[] args) {
        String[][] tests = {
            {"racecar", "true"},
            {"hello", "false"},
            {"A man a plan a canal Panama", "true"},
            {"", "true"}
        };

        for (String[] t : tests) {
            boolean res = isPalindrome(t[0]);
            boolean exp = Boolean.parseBoolean(t[1]);
            String status = (res == exp) ? "✅ PASS" : "❌ FAIL";
            System.out.println(status + " | isPalindrome(\\"" + t[0] + "\\") => " + res);
        }
    }
}
`,
    go: `package main

import (
	"fmt"
	"strings"
	"unicode"
)

func isPalindrome(s string) bool {
	var clean []rune
	for _, r := range s {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			clean = append(clean, unicode.ToLower(r))
		}
	}
	n := len(clean)
	for i := 0; i < n/2; i++ {
		if clean[i] != clean[n-1-i] {
			return false
		}
	}
	return true
}

func main() {
	tests := []struct {
		text     string
		expected bool
	}{
		{"racecar", true},
		{"hello", false},
		{"A man a plan a canal Panama", true},
		{"", true},
	}

	for _, t := range tests {
		res := isPalindrome(t.text)
		status := "✅ PASS"
		if res != t.expected {
			status = "❌ FAIL"
		}
		fmt.Printf("%s | isPalindrome(%q) => %v\\n", status, t.text, res)
	}
}
`,
    rust: `fn is_palindrome(s: &str) -> bool {
    let clean: Vec<char> = s.chars()
        .filter(|c| c.is_alphanumeric())
        .map(|c| c.to_ascii_lowercase())
        .collect();
    let rev: Vec<char> = clean.iter().rev().cloned().collect();
    clean == rev
}

fn main() {
    let tests = vec![
        ("racecar", true),
        ("hello", false),
        ("A man a plan a canal Panama", true),
        ("", true),
    ];

    for (text, expected) in tests {
        let res = is_palindrome(text);
        let status = if res == expected { "✅ PASS" } else { "❌ FAIL" };
        println!("{} | is_palindrome({:?}) => {}", status, text, res);
    }
}
`
  }
};

export function getOrCreateRoom(roomId, title = "Technical Interview") {
  if (!rooms.has(roomId)) {
    rooms.set(roomId, {
      id: roomId,
      title: title,
      createdAt: Date.now(),
      language: "python",
      code: DEFAULT_PROBLEM.starterCode.python,
      question: DEFAULT_PROBLEM.description,
      participants: new Map(), // socketId -> { id, name, role, isMuted, isCamOff }
      messages: [
        {
          id: "sys-" + Date.now(),
          sender: "System",
          role: "system",
          text: "Welcome to the interview session. Both participants have real-time sync for code, video, and chat.",
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }
      ],
      output: null,
      evaluations: []
    });
  }
  return rooms.get(roomId);
}

export function getRoom(roomId) {
  return rooms.get(roomId);
}

export function removeParticipant(roomId, socketId) {
  const room = rooms.get(roomId);
  if (!room) return null;
  const user = room.participants.get(socketId);
  room.participants.delete(socketId);
  return user;
}

export function serializeRoom(room) {
  if (!room) return null;
  return {
    id: room.id,
    title: room.title,
    language: room.language,
    code: room.code,
    question: room.question,
    participants: Array.from(room.participants.values()),
    messages: room.messages,
    output: room.output
  };
}

