# Jekyll Blog

## Local Development

1. Install dependencies

```bash
bundle install
npm install
```

2. Run the server

```bash
bundle exec jekyll serve --config _config.yml,_config-dev.yml --livereload
```

3. Open your browser and navigate to http://localhost:4000

## Github Pages

1. Open repository settings

2. Go to Pages section

3. Select "Deploy from a branch"

4. Set source to "gh-pages"

5. Save

6. Wait for a few minutes

7. Open your browser and navigate to https://{username}.github.io/{repository}