# XProcTwitterBot
A Twitter bot for XML hackers

XProcTwitterBot is a TwitterBot written in the XProc language. The bot includes a number of XProc steps for dealing with Twitter: `<twitter:upload-media>`, `<twitter:tweet>`, `<twitter:followers>`, and `<twitter:sign-request>`.

As an example, the bot also includes steps which search for old newspaper illustrations from the National Library of New Zealand, and uses the `twitter:` XProc steps to republish them as tweets, under the acccount [@NZPaperBot](https://twitter.com/NZPaperBot).

XProcTwitterBot makes a query to the National Library of New Zealand's [DigitalNZ API](http://www.digitalnz.org/developers/api-docs-v3/search-records-api-v3); firstly to search for illustrations published exactly 100 years ago, from which it selects a single result, and retrieves the image itself from that page. After that the bot uploads the image to Twitter, and then creates a tweet containing the headline, the title of the newspaper, a link to the page on Papers Past, and the image itself.

To run this bot, you will need to install the [XMLCalabash](http://xmlcalabash.com/) XProc interpreter, because the Bot makes use of one or two Calabash extensions that aren't available with other XProc engines. I hope to convert it to a fully standard XProc eventually.

You will also need to go to Twitter and [sign up to create a user account for your TwitterBot](https://twitter.com/signup), and also [register an App](https://apps.twitter.com/app/new), and grant your App the right to post on behalf of your user. This will yield four credentials (`consumer-key`, `consumer-secret`, `access-token`, and `access-token-secret`) which you must pass to the `twitter-bot.xpl` pipeline when you run it. e.g.

`java -jar xmlcalabash.jar` `--with-param consumer-key="XXXXXXX"` `--with-param consumer-secret="XXXXXXX"` `--with-param access-token="XXXXXXXX"` `--with-param access-token-secret="XXXXXXX"` `twitter-bot.xpl`


This software is released into the public domain.

