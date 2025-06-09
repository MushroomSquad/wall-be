# Contributing to wall-be

We love your input!

**Language / Язык**: [English](CONTRIBUTING.md) | [Русский](CONTRIBUTING.ru.md)

## Multilingual Documentation

wall-be project supports documentation and code comments in both English and Russian. When contributing:

- For documentation files, provide content in both languages (separate files)
- For code comments, use the format: `# English comment / Русский комментарий`
- For user messages, include both versions: `"English message / Русское сообщение"`

## How to contribute

### Reporting Bugs

1. **Check if the bug already exists**
2. **Create a new issue** using the bug report template
3. **Provide detailed information** about the bug

### Suggesting Features

1. **Check if the feature already exists or has been requested**
2. **Create a new issue** using the feature request template
3. **Explain why the feature would be useful**

### Pull Requests

1. **Fork the repository**
2. **Create a branch** for your feature or bugfix
3. **Add tests** for any new functionality
4. **Ensure all tests pass**
5. **Submit a pull request**

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/MushroomSquad/wall-be.git
   cd wall-be
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

3. **Make your changes**

4. **Run tests**
   ```bash
   ./run_tests.sh
   ```

5. **Commit your changes**
   ```bash
   git commit -m "Add my new feature"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/my-new-feature
   ```

7. **Create a pull request**

## Coding Standards

### Shell Scripts

- Use bash for all shell scripts
- Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- All shell scripts must include bilingual comments
- Use shellcheck to verify your code

### Documentation

- Keep documentation up-to-date
- Use Markdown for all documentation
- Include both English and Russian versions of all documentation (separate files)

## License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.

## Adding Support for a New Database

1. Create scripts in `scripts/new-database/` directory.
2. Create Docker configuration in `docker/new-database/`.
3. Add template configuration file in `config/new-database.env.template`.
4. Add examples in `examples/new-database/`.
5. Add documentation in `docs/databases/en/new-database.md` and `docs/databases/new-database.md`.
6. Update README.md and README.ru.md to mention the newly supported database.

## Testing

Before submitting a pull request, ensure that:

1. All scripts run without errors.
2. All features are properly documented.
3. Docker images build and run successfully.
4. Examples in `examples/` work as expected. 