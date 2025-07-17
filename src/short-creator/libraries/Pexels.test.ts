process.env.LOG_LEVEL = "debug";

import nock from "nock";
import { PexelsAPI } from "./Pexels";
import { test, expect } from "vitest";
import fs from "fs-extra";
import path from "path";

test(
  "should retry 3 times",
  async () => {
    const mockResponse = fs.readFileSync(
      path.resolve("__mocks__/pexels-response.json"),
      "utf-8",
    );
    const scope = nock("https://api.pexels.com")
      .get(/videos\/search/)
      .times(2)
      .reply(500, {})
      .get(/videos\/search/)
      .reply(200, mockResponse);

    const pexels = new PexelsAPI("asdf");
    const video = await pexels.findVideo(["dog"], 2.4, []);
    expect(video).not.toBeNull();
    expect(scope.isDone()).toBe(true);
  },
  10000,
);
