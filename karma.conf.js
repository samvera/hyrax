// Karma configuration
// Generated on Fri May 20 2022 13:13:50 GMT+0000 (Coordinated Universal Time)

require('dotenv').config();

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '.',

    // frameworks to use
    // available frameworks: https://www.npmjs.com/search?q=keywords:karma-adapter
    frameworks: ['jasmine'],

    client: {
      jasmine: {
        random: true,
        oneFailurePerSpec: false,
        failFast: false,
        timeoutInterval: 1000
      }
    },

    // list of files / patterns to load in the browser
    // uses dotenv to allow for .dassie as the Rails root

    files: [
      {pattern: 'spec/javascripts/fixtures/*.html', watched: true, included: false, served: true},
      process.env.RAILS_ROOT + '/public/assets/application-*.js',
      'spec/javascripts/helpers/*',
      'spec/javascripts/*_spec.js',
      'spec/javascripts/*_spec.js.coffee',
    ],

    // list of files / patterns to exclude
    exclude: [
    ],

    // preprocess matching files before serving them to the browser
    // available preprocessors: https://www.npmjs.com/search?q=keywords:karma-preprocessor
    preprocessors: {
      '**/*.coffee': ['coffee']
    },

    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://www.npmjs.com/search?q=keywords:karma-reporter
    reporters: ['spec'],

    specReporter: {
      maxLogLines: 5,             // limit number of lines logged per test
      suppressSummary: false,      // do not print summary
      suppressErrorSummary: false, // do not print error summary
      suppressFailed: false,      // do not print information about failed tests
      suppressPassed: false,      // do not print information about passed tests
      suppressSkipped: false,      // do not print information about skipped tests
      showBrowser: true,         // print the browser for each spec
      showSpecTiming: true,      // print the time elapsed for each spec
      failFast: false,             // test would finish with error when a first fail occurs
      prefixes: {
        success: '    OK: ',      // override prefix for passed tests, default is '✓ '
        failure: 'FAILED: ',      // override prefix for failed tests, default is '✗ '
        skipped: 'SKIPPED: '      // override prefix for skipped tests, default is '- '
      }
    },

    // web server port
    hostname: process.env.KARMA_HOSTNAME || 'localhost', // This is the host the remote browser connects to
    port: 9876,

    // enable / disable colors in the output (reporters and logs)
    colors: true,

    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,

    // start these browsers
    // available browser launchers: https://www.npmjs.com/search?q=keywords:karma-launcher
    browsers: [process.env.KARMA_BROWSER || 'ChromiumHeadless'],

    customLaunchers: {
      'remote-chromium': {
        base: 'SeleniumGrid',
        gridUrl: process.env.HUB_URL || 'http://localhost:4444/wd/hub',
        browserName: 'chrome',
        arguments: [ '--headless=new']
      }
    },

    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: true,

    // Concurrency level
    // how many browser instances should be started simultaneously
    concurrency: 1
  })
}
