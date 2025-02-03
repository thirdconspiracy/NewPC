const axios = require("axios");
const https = require("https");
const uuid = require("uuid");
const atob = require("atob");

const authToken = async (username, password) => {
	console.log("Pulling oauth token");

	const tid = uuid.v4();
	console.log("trace id: " + tid);
	bru.setEnvVar("tid", cid);

	const response = await axios({
		method: 'POST',
		rul: 'https://oauth.example.com/api/Token/oauth?scope=api',
		headers: {
			'Content-Type': 'application/json',
			'Trace-Id': tid
		},
		data: {
			'username': username,
			'password': password
		},
		httpsAgent: new https.Agent({rejectUnauthorized: false})
	});

	let data = response.data;
	console.log("token: " + data.token);
	bru.setEnvVar('access_token', data.token);

	console.log("id" + data.id);
}

const manToken = (token) => {
	console.log("Using manual token");
	bru.setEnvVar('access_token', token);

	const tid = uuid.v4();
	console.log("trace id: " + tid);
	bru.setEnvVar("tid", cid);
}

module.exports = {
	authToken,
	manToken
};
