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

1. Create a github action script in `.github/workflows/gh-pages.yaml`

```yaml
name: Build and deploy this site to GitHub Pages

on:
  push:
    branches:
      - main

jobs:
  github-pages:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1
          bundler-cache: true
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
      - name: Build site
        uses: limjh16/jekyll-action-ts@v2
        with:
          enable_cache: true
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./_site
```
2. Open repository settings

3. Go to Action > General section

4. On "Workflow permissions" select "Read and write permissions"

5. Click save to save the settings

6. After the first action run, it will create "gh-pages" branch

7. Open repository settings

8. Go to Pages section

9. Select "Deploy from a branch"

10. Set source to "gh-pages"

11. Save

12. Open your browser and navigate to https://{username}.github.io/{repository}