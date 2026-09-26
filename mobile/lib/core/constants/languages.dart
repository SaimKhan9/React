// DevArena Live — Programming language definitions with starter code templates

class LanguageConfig {
  final String id;
  final String name;
  final String monacoLang;
  final String displayName;
  final String starterCode;
  final String testInput;

  const LanguageConfig({
    required this.id,
    required this.name,
    required this.monacoLang,
    required this.displayName,
    required this.starterCode,
    this.testInput = '',
  });
}

const List<LanguageConfig> kLanguages = [
  LanguageConfig(
    id: 'python',
    name: 'Python 3',
    monacoLang: 'python',
    displayName: '🐍 Python 3',
    starterCode: '''def solve(n: int) -> int:
    """Solve the problem."""
    pass

# Test
print(solve(5))
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'javascript',
    name: 'JavaScript',
    monacoLang: 'javascript',
    displayName: '🟨 JavaScript',
    starterCode: '''/**
 * @param {number} n
 * @return {number}
 */
function solve(n) {
    // Your solution
}

console.log(solve(5));
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'typescript',
    name: 'TypeScript',
    monacoLang: 'typescript',
    displayName: '🔷 TypeScript',
    starterCode: '''function solve(n: number): number {
    // Your solution here
    return 0;
}

console.log(solve(5));
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'cpp',
    name: 'C++',
    monacoLang: 'cpp',
    displayName: '⚙️ C++',
    starterCode: '''#include <bits/stdc++.h>
using namespace std;

int solve(int n) {
    // Your solution here
    return 0;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    cout << solve(5) << endl;
    return 0;
}
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'java',
    name: 'Java',
    monacoLang: 'java',
    displayName: '☕ Java',
    starterCode: '''import java.util.*;

public class Solution {
    public int solve(int n) {
        // Your solution here
        return 0;
    }
    
    public static void main(String[] args) {
        Solution sol = new Solution();
        System.out.println(sol.solve(5));
    }
}
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'go',
    name: 'Go',
    monacoLang: 'go',
    displayName: '🐹 Go',
    starterCode: '''package main

import "fmt"

func solve(n int) int {
    // Your solution here
    return 0
}

func main() {
    fmt.Println(solve(5))
}
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'rust',
    name: 'Rust',
    monacoLang: 'rust',
    displayName: '🦀 Rust',
    starterCode: '''fn solve(n: i32) -> i32 {
    // Your solution here
    0
}

fn main() {
    println!("{}", solve(5));
}
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'ruby',
    name: 'Ruby',
    monacoLang: 'ruby',
    displayName: '💎 Ruby',
    starterCode: '''def solve(n)
  # Your solution here
  0
end

puts solve(5)
''',
    testInput: '',
  ),
  LanguageConfig(
    id: 'php',
    name: 'PHP',
    monacoLang: 'php',
    displayName: '🐘 PHP',
    starterCode: '''<?php

function solve(int \$n): int {
    // Your solution here
    return 0;
}

echo solve(5) . PHP_EOL;
''',
    testInput: '',
  ),
];

LanguageConfig getLanguageById(String id) {
  return kLanguages.firstWhere(
    (l) => l.id == id,
    orElse: () => kLanguages.first,
  );
}
