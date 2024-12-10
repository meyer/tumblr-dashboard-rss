import * as s from 'superstruct';

export type FlickrPhoto = s.Infer<typeof photoSchema>;

export const photoSchema = s.type({
  id: s.string(),
  secret: s.string(),
  server: s.string(),
  farm: s.number(),
  owner: s.string(),
  username: s.optional(s.string()),
  ownername: s.string(),
  iconfarm: s.optional(s.number()),
  realname: s.optional(s.string()),
  title: s.string(),
  ispublic: s.enums([0, 1]),
  isfriend: s.enums([0, 1]),
  isfamily: s.enums([0, 1]),
  description: s.type({
    _content: s.string(),
  }),
  iconserver: s.string(),
  o_width: s.optional(s.string()),
  o_height: s.optional(s.string()),
  dateupload: s.string(),
  lastupdate: s.string(),
  datetaken: s.string(),
  tags: s.string(),
  media: s.string(),
  url_l: s.string(),
  url_o: s.optional(s.string()),
  height_l: s.number(),
  width_l: s.number(),
  pathalias: s.string(),
});

export const photostreamSchema = s.type({
  photos: s.type({
    photo: s.array(photoSchema),
    total: s.number(),
    page: s.number(),
    per_page: s.optional(s.number()),
    pages: s.number(),
  }),
});
