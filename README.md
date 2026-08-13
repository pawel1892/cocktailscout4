# CocktailScout

<p align="center">
  <img src="public/logo_red.svg" alt="CocktailScout Logo" width="300">
</p>

This is the source code for [cocktailscout.de](https://www.cocktailscout.de), a modern cocktail recipe database and community platform.

**Note:** This is a non-commercial, community-driven project.

## Features

- **Recipe Database**: Thousands of cocktail recipes with ratings, images, and ingredient lists.
- **Community**: Forum, user profiles, and interactive features.
- **"Meine Bar"**: Ingredient-based recipe matching.
- **SEO Optimized**: Full meta tag support, structured data (JSON-LD), and automated sitemaps.
- **Modern Stack**: Built with the latest Rails conventions.

## Tech Stack

- **Framework**: Ruby on Rails 8
- **Database**: MySQL 8.0
- **Frontend**: Tailwind CSS + Vite
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Testing**: RSpec, FactoryBot, Shoulda Matchers
- **Deployment**: Kamal

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
If you are skilled in **Design, UX, or Writing** but don't know how to program, I would still love your help! Please contact me if you'd like to contribute in these areas.

## Installation

This is a standard Ruby on Rails 8 project. For general Rails setup background, see the [official Rails guides](https://guides.rubyonrails.org/getting_started.html).

### Local setup

```
bundle install
bin/rails db:prepare
bin/rails sample_data:import
bin/dev
```

`sample_data:import` loads `db/sample_data`, a small (<50MB) committed snapshot with all reference data (roles, units), all ingredients, ~150 real recipes, ~15-20 real forum threads, and ~10 real wiki articles, images included. Authorship of all sampled content is reassigned to 50 fabricated accounts (no real user data is ever committed) sharing the password `password123` — usernames and role assignments are listed in `db/sample_data/data/users.yml` and `user_roles.yml`. Re-running the import against a non-empty DB requires `FORCE=true` (wipes and reloads the in-scope tables only).

If you have access to the production DB/asset mirror, `bin/rails sample_data:export` regenerates the bundle from a fuller local dataset.

If you need help with the installation or have questions about the setup, please feel free to contact me.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.