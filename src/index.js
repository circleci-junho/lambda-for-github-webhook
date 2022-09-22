const request = require('request');

exports.handler = async (event) => {
  // `envent` will contain github webhook payload
  const payload = JSON.parse(event.body);
  console.log(payload);

  // Each payload have different key/value.
  // This example expecting webhook from pull_request
  // Create conditional funtion or separate Lamdba servide to handle various trigger option.
  const name = payload.pull_request.head.repo.full_name;
  const branch = payload.pull_request.head.ref;
  console.log(name); // circleci-tester
  console.log(branch); // main

  // Setup request option, please check CircleCI API documents
  // https://circleci.com/docs/api/v2/index.html
  const options = {
    method: 'POST',
    url: `https://circleci.com/api/v2/project/gh/${name}/pipeline`,
    headers: {'content-type': 'application/json', "Circle-Token": process.env.Token},
    body: {
      branch: `${branch}`
    },
    json: true
  };

  const response = {
    statusCode: 200,
    body: JSON.stringify(await new Promise((resolve, reject) => {
        request(options, (error, response, body) => {
            if (error) {
                console.log(body);
                reject(error);
            } else {
                resolve(response);
            }
        });
    })),
  };
  return response;
};
