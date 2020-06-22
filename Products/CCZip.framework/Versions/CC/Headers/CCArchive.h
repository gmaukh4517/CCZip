//
//  CCArchive.h
//  CCZip
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, CCOptions) {
    CCOptionsFileCreate = 1,                    // 如果归档文件不存在，请创建它。
    CCOptionsFileExclusive = 2,                 // 如果存档已存在，则错误。
    CCOptionsFileStricterConsistencyChecks = 4, // 对归档文件执行其他更严格的一致性检查，如果检查失败则出错。
    CCOptionsFileTruncate = 8,                  // 如果存档存在，请忽略其当前内容。 换句话说，以与空存档相同的方式处理它。
};

typedef NS_ENUM(int, CCOptionsFile) {
    CCOptionsFileCaseInsensitivePathLookup = 1,      // 忽略路径查找中的大小写
    CCOptionsFileReadCompressedData = 4,             // 读取压缩数据
    CCOptionsFileUseOriginalDataIgnoringChanges = 8, // 使用原始数据，忽略更改
    CCOptionsFileForceRecompressionOfData = 16,      // 强制重新压缩数据
    CCOptionsFileWantEncryptedData = 32,             // 读取加密的数据（意味着CCOptionsFileReadCompressedData）
    CCOptionsFileWantUnmodifiedString = 64,          // 获取未修改的字符串
    CCOptionsFileOverwrite = 8192                    // 将文件添加到ZIP存档中并且存在具有相同路径的文件时，请替换它
};

@class CCArchiveEntry;

@interface CCArchive : NSObject

/// 文件路径
@property (nonatomic, readonly, copy) NSURL *URL;

/// 压缩包文件数量
@property (nonatomic, readonly) NSInteger fileCount;

/// 读取压缩包
/// @param fileURL 文件路劲地址
/// @param error 执行错误
+ (CCArchive *)archiveWithURL:(NSURL *)fileURL error:(NSError **)error;

/// 读取压缩包
/// @param fileURL 文件路劲地址
/// @param options 读取方式
/// @param error 执行错误
+ (CCArchive *)archiveWithURL:(NSURL *)fileURL options:(CCOptions)options error:(NSError **)error;

/// 压缩文件
/// @param filePath 压缩文件路径
/// @param toFilePath 压缩路径
/// @param error 执行错误
+ (BOOL)zipFileAtPath:(NSString *)filePath toFilePath:(NSString *)toFilePath error:(NSError **)error;

/// 解压压缩包
/// @param zipPath 压缩包路径
/// @param toZipPath 解压路径
/// @param error 执行错误
+ (BOOL)unzipFIleAtpath:(NSString *)zipPath toZipPath:(NSString *)toZipPath error:(NSError **)error;

/// 读取压缩包
/// @param fileURL 文件路劲地址
/// @param error 执行错误
- (CCArchive *)initWithURL:(NSURL *)fileURL error:(NSError **)error;

/// 读取压缩包
/// @param fileURL 文件路劲地址
/// @param options 读取方式
/// @param error 执行错误
- (CCArchive *)initWithURL:(NSURL *)fileURL options:(CCOptions)options error:(NSError **)error;

/// 读取压缩包
/// @param filePath 文件路劲地址
/// @param options 读取方式
/// @param error 执行错误
- (CCArchive *)initWithPath:(NSString *)filePath options:(CCOptions)options error:(NSError **)error;

/// 索引读取文件的对象
/// @param index 下标
/// @param error 执行错误
- (CCArchiveEntry *)archiveFileWithIndex:(NSUInteger)index error:(NSError **)error;

/// 索引读取文件的对象
/// @param index 下标
/// @param options 读取方式
/// @param error 执行错误
- (CCArchiveEntry *)archiveFileWithIndex:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;

/// 路径读取文件的对象
/// @param filePath 文件路径
/// @param error 执行错误
- (CCArchiveEntry *)archiveWithFilePath:(NSString *)filePath error:(NSError **)error;

/// 路径读取文件的对象
/// @param filePath 文件路径
/// @param options 读取方式
/// @param error 执行错误
- (CCArchiveEntry *)archiveWithFilePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;

/// 索引读取文件
/// @param index 下标
/// @param error 执行错误
- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;

/// 索引读取文件
/// @param index 下标
/// @param options 读取方式
/// @param error 执行错误
- (NSData *)dataForFileAtIndex:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;

/// 路径读取文件
/// @param filePath 文件路径
/// @param error 执行错误
- (NSData *)dataForFilePath:(NSString *)filePath error:(NSError **)error;

/// 路径读取文件
/// @param filePath 文件路径
/// @param options 读取方式
/// @param error 执行错误
- (NSData *)dataForFilePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;

/// 文件对象读取文件数据
/// @param zippedFileInfo 文件对象
/// @param error 执行错误
- (NSData *)dataForZippedFileInfo:(CCArchiveEntry *)zippedFileInfo error:(NSError **)error;

/// 文件对象读取文件数据
/// @param zippedFileInfo 文件对象
/// @param options 读取方式
/// @param error 执行错误
- (NSData *)dataForZippedFileInfo:(CCArchiveEntry *)zippedFileInfo options:(CCOptionsFile)options error:(NSError **)error;

/// 往压缩包添加文件夹
/// @param folderPath 文件层级路径结尾是创建文件夹名称
/// @param error 执行错误
- (BOOL)addFolderWithPath:(NSString *)folderPath error:(NSError **)error;

/// 往压缩包添加文件或文件夹
/// @param filePath 文件层级路径 结尾+/是创建文件夹
/// @param data 文件数据
/// @param error 执行错误
- (BOOL)addFileWithPath:(NSString *)filePath forData:(NSData *)data error:(NSError **)error;

/// 替换压缩文件
/// @param zippedFileInfo 文件对象
/// @param xmlData 文件数据
/// @param error 执行错误
- (BOOL)replaceFile:(CCArchiveEntry *)zippedFileInfo withData:(NSData *)xmlData error:(NSError **)error;

/// 保存数据
/// @param error 执行错误
- (BOOL)saveAndReturnError:(NSError **)error;

@end
