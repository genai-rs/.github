# Contributing to GenAI-RS

Thank you for your interest in contributing to GenAI-RS! We're excited to have you join our community of Rust developers building the future of AI.

## 🎯 Our Values

- **Quality over Quantity** - Well-tested, documented code is better than rushed features
- **Performance Matters** - We optimize for speed and efficiency
- **Developer Experience** - APIs should be intuitive and ergonomic
- **Community First** - Be welcoming, helpful, and respectful

## 🚀 Getting Started

### Prerequisites

- Rust 1.75 or later
- Git
- A GitHub account
- Familiarity with Rust and async programming

### Development Setup

1. Fork the repository you want to contribute to
2. Clone your fork:
```bash
git clone https://github.com/YOUR_USERNAME/PROJECT_NAME.git
cd PROJECT_NAME
```

3. Add the upstream remote:
```bash
git remote add upstream https://github.com/genai-rs/PROJECT_NAME.git
```

4. Create a new branch:
```bash
git checkout -b feature/your-feature-name
```

## 🔧 Development Workflow

### Code Style

We use standard Rust formatting and linting tools:

```bash
# Format your code
cargo fmt

# Check for common mistakes
cargo clippy -- -D warnings

# Run tests
cargo test

# Build documentation
cargo doc --no-deps --open
```

### Commit Messages

We follow conventional commits for clear history:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions or modifications
- `perf:` Performance improvements
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

Example:
```
feat: add streaming support for OpenAI provider

- Implement AsyncIterator for chat responses
- Add backpressure handling
- Update examples with streaming usage
```

### Testing

All new features and bug fixes must include tests:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_feature() {
        // Your test here
    }
}
```

### Documentation

- Add doc comments to all public APIs
- Include examples in doc comments
- Update README if adding major features
- Consider adding a tutorial for complex features

Example:
```rust
/// Sends a chat completion request to the LLM provider.
///
/// # Examples
///
/// ```rust
/// use genai::prelude::*;
///
/// async fn example() -> Result<(), Box<dyn std::error::Error>> {
///     let client = Client::new("openai", "api-key")?;
///     let response = client.chat()
///         .message("Hello!")
///         .send()
///         .await?;
///     Ok(())
/// }
/// ```
pub async fn send(&self) -> Result<Response> {
    // Implementation
}
```

## 📝 Pull Request Process

1. **Update your fork**
```bash
git fetch upstream
git rebase upstream/main
```

2. **Make your changes**
- Write clean, documented code
- Add tests for new functionality
- Update documentation as needed

3. **Validate your changes**
```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test
cargo doc --no-deps
```

4. **Push to your fork**
```bash
git push origin feature/your-feature-name
```

5. **Create a Pull Request**
- Use a clear, descriptive title
- Reference any related issues
- Describe what changes you've made
- Include examples if applicable

6. **Code Review**
- Address reviewer feedback promptly
- Be open to suggestions
- Ask questions if something is unclear

## 🐛 Reporting Issues

### Bug Reports

Please include:
- Rust version (`rustc --version`)
- Project version
- Minimal reproduction code
- Expected vs actual behavior
- Error messages/stack traces

### Feature Requests

Please include:
- Use case description
- Proposed API/interface
- Alternative solutions considered
- Potential implementation approach

## 💡 Types of Contributions

### Good First Issues

Look for issues labeled `good-first-issue` - these are great for newcomers!

### Documentation

- Fix typos and grammar
- Add examples
- Write tutorials
- Improve API docs

### Code Contributions

- Bug fixes
- New features
- Performance improvements
- Test coverage
- Refactoring

### Community

- Answer questions in discussions
- Review pull requests
- Share your projects using our libraries
- Write blog posts or tutorials

## 🏗️ Architecture Guidelines

### Error Handling

Use `thiserror` for error types:

```rust
#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("API request failed: {0}")]
    ApiError(String),

    #[error("Invalid configuration: {0}")]
    ConfigError(String),
}
```

### Async Design

- Use `tokio` for async runtime
- Implement cancellation where appropriate
- Consider backpressure in streaming APIs

### API Design

- Builder pattern for complex configurations
- Trait-based abstractions for extensibility
- Zero-cost abstractions where possible

## 🤝 Community Guidelines

- Be respectful and inclusive
- Help others learn and grow
- Give credit where it's due
- Focus on constructive feedback
- Celebrate successes together

## 📮 Contact

- **GitHub Discussions**: [Ask questions](https://github.com/orgs/genai-rs/discussions)
- **Email**: genai-rs@timvw.be

## 📜 License

By contributing, you agree that your contributions will be dual-licensed under Apache-2.0 and MIT.

---

Thank you for contributing to GenAI-RS! Together, we're building the future of AI in Rust. 🦀✨