FROM rocket.chat:3.18

USER root

RUN apt-get update && apt-get install -y jq

COPY assets/program.json /app/bundle/program.json

COPY assets/fonts/ /app/bundle/programs/web.browser/app/fonts/
RUN chown -R rocketchat:rocketchat /app/bundle/programs/web.browser/app/fonts
RUN jq 'reduce inputs.manifest as $s (.; .manifest += $s)' /app/bundle/programs/web.browser/program.json /app/bundle/program.json > /app/bundle/programs/web.browser/program_ed.json \
    && cp /app/bundle/programs/web.browser/program_ed.json /app/bundle/programs/web.browser/program.json

COPY assets/fonts/ /app/bundle/programs/web.browser.legacy/app/fonts/
RUN chown -R rocketchat:rocketchat /app/bundle/programs/web.browser.legacy/app/fonts
RUN jq 'reduce inputs.manifest as $s (.; .manifest += $s)' /app/bundle/programs/web.browser.legacy/program.json /app/bundle/program.json > /app/bundle/programs/web.browser.legacy/program_ed.json \
    && cp /app/bundle/programs/web.browser.legacy/program_ed.json /app/bundle/programs/web.browser.legacy/program.json

USER rocketchat