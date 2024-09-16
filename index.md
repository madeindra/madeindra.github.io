---
layout: page
title: "Home"
---

<div class="prose dark:prose-invert max-w-prose mx-auto text-center">

  <!-- Welcome Message -->

  {% if site.homepage.welcome.title %}

  <div class="py-6 px-6 mb-8">
    <h2 class="text-2xl font-bold mb-2">{{ site.homepage.welcome.title }}</h2>

    {% if site.homepage.welcome.subtitle %}
    <p class="text-gray-700 dark:text-gray-300">
      {{ site.homepage.welcome.subtitle }}
    </p>
    {% endif %}

  </div>
  {% endif %}

  <div class="space-y-12">
    {% for post in site.posts %}
    <div class="flex items-start space-x-6">
      <div class="flex-1">

        <!-- Date, Reading Time, Category -->
        <div class="flex items-center text-sm text-gray-500 dark:text-gray-500 mb-2">
          <span>{{ post.date | date: "%d %B %Y" }}</span>
          <span class="mx-2">•</span>
          <span>{{ post.content | number_of_words | divided_by: 200 | plus: 1 }} min read</span>
          <span class="mx-2">•</span>
          <span>{{ post.category }}</span>
        </div>

        <!-- Title, Summary, Image -->
        <div class="flex items-start space-x-6">
          <div class="flex-1">

            <a href="{{ post.url | relative_url }}">
              <h2 class="text-xl font-semibold mb-2 text-left">{{ post.title }}</h2>
            </a>

            {% if post.description %}
            <p class="text-gray-600 dark:text-gray-400 text-justify">{{ post.description }}</p>
            {% else %}
            <p class="text-gray-600 dark:text-gray-400 text-justify">{{ post.content | strip_html | truncatewords: 30 }}</p>
            {% endif %}

          </div>

          {% if post.image %}
          <a href="{{ post.url | relative_url }}">
            <img src="{{ post.image }}" alt="{{ post.title }}" class="w-32 h-32 object-cover rounded">
          </a>
          {% endif %}

        </div>

      </div>
    </div>
    {% endfor %}

  </div>
</div>