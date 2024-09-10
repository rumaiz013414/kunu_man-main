const wdio = require('webdriverio');

const opts = {
  path: '/wd/hub',
  port: 4723,
  capabilities: {
    platformName: "Android",
    deviceName: "Android Emulator",
    app: "/Users/user2/Downloads/DOGGY-FINAL-KUNU-master/build/app/outputs/flutter-apk/app-debug.apk",
    automationName: "Flutter",
  },
};

(async () => {
  const client = await wdio.remote(opts);

  // Find the email field and enter a value
  const emailField = await client.elementByFlutter('byValueKey', 'emailField');
  await emailField.setValue('test@example.com');

  // Find the password field and enter a value
  const passwordField = await client.elementByFlutter('byValueKey', 'passwordField');
  await passwordField.setValue('password123');

  // Find and click the login button
  const loginButton = await client.elementByFlutter('byValueKey', 'loginButton');
  await loginButton.click();

  // Optionally, add assertions to verify the outcome

  await client.deleteSession();
})();
