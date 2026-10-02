const path = require('path');

require('./utils/execLogger');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
require('./jobs/execJobs');
