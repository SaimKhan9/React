export const LANGUAGES = [
  {
    id: "python",
    name: "Python 3",
    judge0Id: 92,
    monacoLang: "python",
    icon: "🐍",
    extension: ".py",
    sample: `def is_palindrome(s: str) -> bool:
    """Check if string is palindrome (case-insensitive & alphanumeric only)"""
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
`
  },
  {
    id: "javascript",
    name: "JavaScript (Node)",
    judge0Id: 93,
    monacoLang: "javascript",
    icon: "🟨",
    extension: ".js",
    sample: `function isPalindrome(s) {
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
`
  },
  {
    id: "typescript",
    name: "TypeScript",
    judge0Id: 94,
    monacoLang: "typescript",
    icon: "🔷",
    extension: ".ts",
    sample: `function isPalindrome(s: string): boolean {
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
`
  },
  {
    id: "cpp",
    name: "C++ (GCC)",
    judge0Id: 105,
    monacoLang: "cpp",
    icon: "⚙️",
    extension: ".cpp",
    sample: `#include <iostream>
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
`
  },
  {
    id: "java",
    name: "Java (JDK)",
    judge0Id: 91,
    monacoLang: "java",
    icon: "☕",
    extension: ".java",
    sample: `import java.util.*;

public class Main {
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
`
  },
  {
    id: "go",
    name: "Go",
    judge0Id: 95,
    monacoLang: "go",
    icon: "🐹",
    extension: ".go",
    sample: `package main

import (
	"fmt"
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
`
  },
  {
    id: "rust",
    name: "Rust",
    judge0Id: 108,
    monacoLang: "rust",
    icon: "🦀",
    extension: ".rs",
    sample: `fn is_palindrome(s: &str) -> bool {
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
  },
  {
    id: "ruby",
    name: "Ruby",
    judge0Id: 72,
    monacoLang: "ruby",
    icon: "💎",
    extension: ".rb",
    sample: `def palindrome?(s)
  clean = s.downcase.gsub(/[^a-z0-9]/, '')
  clean == clean.reverse
end

tests = [
  ["racecar", true],
  ["hello", false],
  ["A man a plan a canal Panama", true],
  ["", true]
]

tests.each do |text, expected|
  result = palindrome?(text)
  status = result == expected ? "✅ PASS" : "❌ FAIL"
  puts "#{status} | palindrome?(#{text.inspect}) => #{result}"
end
`
  },
  {
    id: "php",
    name: "PHP",
    judge0Id: 98,
    monacoLang: "php",
    icon: "🐘",
    extension: ".php",
    sample: `<?php
function isPalindrome($s) {
    $clean = strtolower(preg_replace('/[^a-z0-9]/', '', $s));
    return $clean === strrev($clean);
}

$tests = [
    ["racecar", true],
    ["hello", false],
    ["A man a plan a canal Panama", true],
    ["", true]
];

foreach ($tests as [$text, $expected]) {
    $result = isPalindrome($text);
    $status = ($result === $expected) ? "✅ PASS" : "❌ FAIL";
    echo $status . " | isPalindrome('" . $text . "') => " . ($result ? 'true' : 'false') . "\\n";
}
?>
`
  }
];

export const getLanguageById = (id) => {
  return LANGUAGES.find((lang) => lang.id === id) || LANGUAGES[0];
};

