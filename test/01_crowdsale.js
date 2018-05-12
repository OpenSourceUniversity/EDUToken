import assertRevert from '../../helpers/assertRevert';
import { inLogs } from '../../helpers/expectEvent';
import Promise from 'bluebird';
import time from '../helpers/time';

// Test

var EDUToken = artifacts.require("./EDUToken.sol");



var Promise = require('bluebird')
var time = require('../helpers/time')

import shouldBehaveLikeBurnableToken from './BurnableToken.behaviour';

require('chai').use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();
