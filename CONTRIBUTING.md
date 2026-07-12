# Contributing to UniFlow

Thank you for considering contributing to UniFlow! We welcome contributions from the community.

## How to Contribute

### Reporting Bugs

Before submitting a bug report, please check if it has already been reported by searching existing issues. When you submit a bug report, please include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs. actual behavior
- Screenshots or code snippets if applicable
- Your environment (Xcode version, Swift version, platform versions)

### Suggesting Features

Feature requests are welcome! Please open an issue with:

- A clear and descriptive title
- A detailed description of the feature
- Why this feature would be useful to the community
- Any potential implementation considerations

### Submitting Code Changes

1. Fork the repository
2. Create a new branch for your feature or bug fix (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Ensure your code follows our coding standards
5. Add tests if applicable, add tests for your changes
6. Commit your changes (`git commit -m 'Add some amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Development Setup

1. Clone the repository: `git clone https://github.com/yourusername/UniFlow.git`
2. Open `UniFlow.xcworkspace` in Xcode
3. Select the appropriate scheme (UniFlow, CounterExample, etc.)
4. Build and test to ensure everything works

## Coding Style

We follow the Swift API Design Guidelines with a few additional conventions:

- Use `final` for classes that shouldn't be subclassed
- Prefer structs over classes when appropriate
- Use descriptive variable and function names
- Keep functions focused on a single responsibility
- Add documentation comments for public APIs
- Use SwiftLint for linting (configuration in `.swiftlint.yml`)

## Running Tests

To run the unit tests:
1. Select the test target in Xcode
2. Press Cmd+U or choose Product > Test

## Documentation

Documentation is written using markdown and Xcode's documentation comments. When adding new features:
- Update the README.md if it affects usage
- Add documentation comments to new public APIs
- Consider adding examples to the Examples directory

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

## License

By contributing to UniFlow, you agree that your contributions will be licensed under the MIT License.