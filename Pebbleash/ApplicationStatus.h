/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Billy Millare
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * ApplicationStatus.h
 *
 *  Created on: Jan 26, 2014
 *      Author: Billy
 */

#ifndef Pebbleash_ApplicationStatus_h
#define Pebbleash_ApplicationStatus_h

#define ApplicationIconBadgeNumber              [UIApplication sharedApplication].applicationIconBadgeNumber
#define SetApplicationIconBadgeNumber(number)   ApplicationIconBadgeNumber = number
#define SetDisabled()                           SetApplicationIconBadgeNumber(2)
#define SetDisconnected()                       SetApplicationIconBadgeNumber(1)
#define SetConnected()                          SetApplicationIconBadgeNumber(0)

#endif
