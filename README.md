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

1. Make sure the Gemfile.lock has `x86_64-linux` platform so it can run in Github Action. Run this if necessary.

```
bundle lock --add-platform x86_64-linux
```

2. Create a github action script in `.github/workflows/gh-pages.yaml`

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
3. Open repository settings

4. Go to Action > General section

5. On "Workflow permissions" select "Read and write permissions"

6. Click save to save the settings

7. After the first action run, it will create "gh-pages" branch

8. Open repository settings

9. Go to Pages section

10. Select "Deploy from a branch"

11. Set source to "gh-pages"

12. Save

13. Open your browser and navigate to https://{username}.github.io/{repository}

## Scripts

### Create New Post

Create a new blog post with interactive prompts:
```markdown
make post
```

Create a new blog post with a specified title:
```markdown
make post title="My New Post"
```

Create a new blog post with a specified title and date:
```markdown
make post title="My New Post" date="2024-12-31"
```

### Download Random Image

Download a random image with a specified query:
```markdown
make image query="person sitting"
```

### Compress Image

Compress image to WebP format:
```markdown
make compress image="/path/to/images.ext"
```