import type { FeedItem } from '~/jsonfeed';
import type { LegacyPost } from '~/utils/tumblr/tumblrApi';
import { unicode } from '~/utils/unicode';
import { howmany, img, ucfirst, wrapHTMLMaybe } from '~/utils/utils';

export const getFeedItemsForPosts = (posts: LegacyPost[]): FeedItem[] => {
  const feedItems: FeedItem[] = [];

  for (const post of posts) {
    const post_title: string[] = [];
    const post_content: string[] = [];
    const post_footer = ['<hr>'];

    const tags = post.tags.map(
      (t) =>
        `<a href=\'http://${post.blog_name}.tumblr.com/tagged/${encodeURIComponent(t)}\'>#${t}</a>`
    );

    if ('title' in post && post.title) {
      post_title.push(post.title);
    } else {
      post_title.push(`${ucfirst(post.type)}`);
    }

    // Add reblog info
    // TODO: Handle answers specially. x answered y, x ⇄ y answered z
    if ('reblogged_from_name' in post && post.reblogged_from_name) {
      let reblog_src = post.reblogged_from_name;
      if (
        'reblogged_root_name' in post &&
        post.reblogged_root_name !== post.reblogged_from_name
      ) {
        reblog_src = `${post.reblogged_from_name} … ${post.reblogged_root_name}`;
      }

      post_title.push(`${post.blog_name} ${unicode.reblogIcon} ${reblog_src}`);
    } else {
      if (post.type === 'answer') {
        post_title.push(
          `${post.blog_name} ${unicode.answerIcon} ${post.asking_name}`
        );
      } else {
        post_title.push(`${post.blog_name}`);
      }
    }

    if ('note_count' in post) {
      post_footer.push(`<p>${howmany(post.note_count, 'note')}</p>`);
    }
    if (tags.length > 0) {
      post_footer.push(`<p>${tags.join(', ')}</p>`);
    }

    if (post.source_url) {
      post_footer.push(
        `<p>Source: <a href="${post.source_url}">${post.source_title}</a></p>`
      );
    }

    if (post.liked) {
      post_footer.push(`<p>${unicode.check} Liked</p>`);
    }

    // tumblr://x-callback-url/blog?blogName=tumblr-username
    // tumblr://x-callback-url/blog?blogName=tumblr-username&postID=post-id
    const tumblrPostURL = `http://www.tumblr.com/open/app?app_args=blog%3FblogName%3D${post.blog_name}%26page%3Dpermalink%26postID%3D${post.id}`;
    post_footer.push(
      `<p><a href="${tumblrPostURL}">View in Tumblr app</a></p>`
    );

    switch (post.type) {
      case 'photo':
      case 'link': {
        const desc: string[] = [];

        if ('caption' in post && post.caption) {
          desc.push(`${post.caption}`.trim());
        }

        // Link posts
        if ('description' in post && post.description) {
          desc.push(`${post.description}`.trim());
        }
        if ('excerpt' in post && post.excerpt) {
          desc.push(`${post.excerpt}`.trim());
        }

        if ('photos' in post && post.photos) {
          const photoFeedItems = post.photos
            .map((photo, idx, arr): FeedItem => {
              let titleSuffix = '';
              if (arr.length > 1) {
                titleSuffix = ` (${idx + 1} of ${arr.length})`;
              }

              const title =
                post_title.join(` ${unicode.bullet} `) + titleSuffix;

              const photo_desc = desc.slice(0);

              // Photo posts
              if (photo.caption) {
                photo_desc.unshift(wrapHTMLMaybe(photo.caption, 'p'));
              }

              const newDesc = [
                '<div>',
                img(
                  photo.original_size.url,
                  photo.original_size.width,
                  photo.original_size.height
                ),
                '</div>',
                photo_desc,
                ...(photo_desc.length > 0
                  ? post_footer
                  : post_footer.slice(1, post_footer.length)),
                `<p>Post URL: <a href='${post.post_url}'>${post.post_url}</a></p>`,
              ].join('\n\n');

              return {
                title,
                summary: newDesc,
                id: photo.original_size.url,
                content_html: [newDesc, ...post_footer].join('\n\n'),
                image: photo.original_size.url,
                url: photo.original_size.url,
                tags: post.tags,
                date_published: new Date(post.date).toISOString(),
                authors: [{ name: post.blog_name }],
              };
            })
            .reverse();

          feedItems.push(...photoFeedItems);
          continue;
        }

        if (post.type === 'link') {
          post_content.push(...desc);

          post_content.push(`<a href='${post.url}'>Link</a>`);
        } else {
          post_content.push('<p><strong>Empty Photo Post :....(</strong></p>');
        }

        break;
      }

      case 'text':
        post_content.push(post.body);
        break;

      case 'quote':
        post_content.push(wrapHTMLMaybe(post.text, 'p'));
        post_content.push(
          `<p>${unicode.mdash}${unicode.thinsp}${post.source}</p>`
        );
        break;

      case 'chat':
        post_content.push('<table>');

        for (const line of post.dialogue) {
          post_content.push(
            `<tr>
  <th align=left>${line.name}</th>
  <td>${line.phrase}</td>
</tr>`
          );
        }

        post_content.push('</table>');
        break;

      case 'audio':
        post_content.push(post.player);
        post_content.push(post.caption);
        break;

      case 'video':
        post_content.push(post.player.pop()!.embed_code);
        break;

      case 'answer': {
        const avatarSize = 128;

        let asker: string;

        if (post.asking_name === 'Anonymous') {
          asker = [
            img(
              `https://secure.assets.tumblr.com/images/anonymous_avatar_${avatarSize}.gif`,
              avatarSize,
              avatarSize,
              { style: 'vertical-align: middle' }
            ),
            post.asking_name,
          ].join('');
        } else {
          asker = [
            `<a href="${post.asking_url}">`,
            img(
              `http://api.tumblr.com/v2/blog/${post.asking_name}.tumblr.com/avatar/${avatarSize}`,
              avatarSize,
              avatarSize,
              { style: 'vertical-align: middle' }
            ),
            post.asking_name,
            '</a>',
          ].join('');
        }

        post_content.push(
          `<blockquote><p><strong>${asker}</strong>: ${post.question}</p></blockquote>`
        );
        post_content.push(post.answer);
        break;
      }

      default:
        console.log(`Unsupported post type: ${(post as any).type}`);
        post_content.push(
          `${ucfirst((post as any).type)} posts not supported (yet!)`
        );
    }

    feedItems.push({
      title: post_title.join(` ${unicode.bullet} `),
      id: post.post_url,
      content_html: [...post_content, ...post_footer].join('\n\n'),
      url: post.post_url,
      tags: post.tags,
      date_published: new Date(post.date).toISOString(),
      authors: [{ name: post.blog_name }],
    });
  }

  return feedItems;
};
