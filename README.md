<p align="center">
  <img src="public/logo_red.svg" alt="CocktailScout Logo" width="400">
</p>

# CocktailScout

This is the source code for [cocktailscout.de](https://www.cocktailscout.de), a modern cocktail recipe database and community platform.

## Features

- **Recipe Database**: Thousands of cocktail recipes with ratings, images, and ingredient lists.
- **Community**: Forum, user profiles, and interactive features.
- **"Meine Bar"**: Ingredient-based recipe matching.
- **Modern Stack**: Built with the latest Rails conventions.

## Tech Stack

- **Framework**: Ruby on Rails 8
- **Database**: MySQL 8.0
- **Frontend**: Tailwind CSS 4.x / Vue 3.x + Vite
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Testing**: RSpec, FactoryBot, Shoulda Matchers
- **Deployment**: Kamal

## Installation

Getting started with a Rails 8 application is straightforward. Ensure you have Ruby 3.3+ and MySQL installed.

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/jpzoidberg/cocktailscout4.git
    cd cocktailscout4
    ```

2.  **Install dependencies**:
    ```bash
    bundle install
    npm install
    ```

3.  **Setup the database**:
    ```bash
    bin/rails db:setup
    ```

4.  **Run the development server**:
    ```bash
    bin/dev
    ```

For detailed guides on running Rails 8, refer to the [official Rails guides](https://guides.rubyonrails.org/getting_started.html).

## Contributing

Contributions are welcome! Whether you are a developer, designer, or writer, your help is appreciated.

### Bug Reports & Feature Requests
If you find a bug or have an idea for a new feature, please open an issue.

### For Developers
1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add some amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.

### Design, UX & Copywriting
If you are skilled in **Design, UX, SEO or Writing** but don't know how to program, I would still love your help! Please contact me if you'd like to contribute in these areas.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.