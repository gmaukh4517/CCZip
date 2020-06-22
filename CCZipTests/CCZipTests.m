//
//  CCZipTests.m
//  CCZipTests
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <CCZip/CCZip.h>
#import <XCTest/XCTest.h>

@interface CCZipTests : XCTestCase

@end

@implementation CCZipTests

- (void)setUp
{
    // Put setup code here. This method is called before the invocation of each test method in the class.

    NSError *error = nil;

    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *zipPath = [testBundle URLForResource:@"test" withExtension:@"zip"].path;

    NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *toPath = [docsdir stringByAppendingPathComponent:zipPath.lastPathComponent.stringByDeletingPathExtension];

    CCArchive *zipArchive = [[CCArchive alloc] initWithURL:[testBundle URLForResource:@"test" withExtension:@"zip"] error:nil];
    if (zipArchive == nil) {
        NSLog(@"%@", error);
    }
    
    CCArchiveEntry *zippedFileInfo = [zipArchive archiveFileWithIndex:0 error:nil];
    NSString *path = zippedFileInfo.path;
    
    [zipArchive addFileWithPath:[NSString stringWithFormat:@"%@2/",path] forData:[@"1111" dataUsingEncoding:NSUTF8StringEncoding] error:&error];
    NSLog(@"111111%@", error);
    [zipArchive addFolderWithPath:[NSString stringWithFormat:@"%@3/",path] error:&error];
    NSLog(@"222222%@", error);
     [zipArchive saveAndReturnError:nil];

    [CCArchive unzipFIleAtpath:zipPath toZipPath:toPath error:&error];
    NSLog(@"%@", error);
    [CCArchive zipFileAtPath:toPath toFilePath:[NSString stringWithFormat:@"%@.zip", toPath] error:&error];
    NSLog(@"%@", error);
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample
{
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
