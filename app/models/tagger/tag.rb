module Tagger
  class Tag < ActiveRecord::Base
  	has_and_belongs_to_many :topic, :class_name => "Topic"

    def self.cloud_for_topic(topic_id)
      tags = $redis.get("tag_cloud_for_topic_#{topic_id}")

      return Marshal.load(tags) unless tags.nil?

      tags = Tagger::Tag.select("tagger_tags.title, COUNT(tagger_tags_topics.topic_id) as count")
                   .group("tagger_tags.id")
                   .joins(:topic)
                   .where("tagger_tags_topics.topic_id IN (SELECT tagger_tags_topics.topic_id FROM tagger_tags_topics WHERE tagger_tags_topics.tag_id in (SELECT tagger_tags_topics.tag_id FROM tagger_tags_topics WHERE tagger_tags_topics.topic_id = ? )) ", topic_id)
      $redis.setex("tag_cloud_for_topic_#{topic_id}", 15.minutes, Marshal.dump(tags))

      tags
    end

    def self.default_cloud
      tags = $redis.get("default_tag_cloud")

      return Marshal.load(tags) unless tags.nil?

      tags = Tagger::Tag.select("tagger_tags.title, COUNT(tagger_tags_topics.topic_id) as count")
                    .group("tagger_tags.id")
                    .joins(:topic)
      $redis.setex("default_tag_cloud", 15.minutes, Marshal.dump(tags))
      tags
    end

    def self.cloud_for_category(slug)
      tags = $redis.get("tag_cloud_to_category_#{slug}")

      return Marshal.load(tags) unless tags.nil?

      tags = Tagger::Tag.select("tagger_tags.title, COUNT(tagger_tags_topics.topic_id) as count")
              .group("tagger_tags.id")
              .joins(:topic)
              .where("tagger_tags_topics.topic_id IN (SELECT topics.id FROM topics INNER JOIN categories ON topics.category_id = categories.id WHERE categories.slug = ?) ", slug)
      $redis.setex("tag_cloud_to_category_#{slug}", 15.minutes, Marshal.dump(tags))
    end

    def self.cloud_for_tag(tag)
      tags = $redis.get("tag_cloud_to_tag_#{tag}")

      return Marshal.load(tags) unless tags.nil?      

      tags = Tagger::Tag.select("tagger_tags.title, COUNT(tagger_tags_topics.topic_id) as count")
              .where("tagger_tags.title != ?", tag)
              .group("tagger_tags.id").
              joins(:topic)
              .where("tagger_tags_topics.topic_id IN (SELECT tagger_tags_topics.topic_id FROM tagger_tags_topics INNER JOIN tagger_tags ON tagger_tags_topics.tag_id = tagger_tags.id WHERE tagger_tags.title = ?) ", tag)

      $redis.setex("tag_cloud_to_tag_#{tag}", 15.minutes, Marshal.dump(tags))
    end

  end
end
