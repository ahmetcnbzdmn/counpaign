const express = require('express');
const router = express.Router();
const terminalController = require('../controllers/terminalController');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Base path: /api/terminal
// All routes require authentication and 'terminal' role
router.use(authMiddleware);
router.use(roleMiddleware(['terminal']));

router.post('/transaction', terminalController.processTransaction);

module.exports = router;
