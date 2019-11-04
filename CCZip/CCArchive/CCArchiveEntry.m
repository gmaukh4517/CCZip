//
//  CCArchiveEntry.m
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

#import "CCArchiveEntry.h"
#import "CCArchive.h"
#import "zip.h"

NSString *const CCArchiveFileInfoErrorDomain = @"com.CCArchive.Error.JXZippedFileInfo";

#define kJXCouldNotAccessZippedFileInfo 1101


@interface CCArchiveEntry ()

@property (nonatomic, copy) NSString *path;              // path of the file
@property (nonatomic, copy) NSString *fileName;          // path of the file
@property (nonatomic, assign) NSUInteger index;          // index within the archive
@property (nonatomic, assign) NSUInteger size;           // size of the file (uncompressed)
@property (nonatomic, assign) NSUInteger compressedSize; // size of the file (compressed)
@property (nonatomic, copy) NSDate *modificationDate;    // modification date

@property (nonatomic, assign) BOOL hasCRC;
@property (nonatomic, assign) uint32_t CRC; // crc of file data

// To get more info about the values returned from the following two methods,
// check the libzip header file for now!
@property (nonatomic, assign) uint16_t compressionMethod; // compression method used
@property (nonatomic, assign) uint16_t encryptionMethod;  // encryption method used

@end


@implementation CCArchiveEntry {
    struct zip_stat _file_info;
}

- (CCArchiveEntry *)initFileInfoWithArchive:(struct zip *)archive
                                      index:(NSUInteger)index
                                   filePath:(NSString *)filePath
                                    options:(CCOptionsFile)options
                                      error:(NSError **)error;
{
    ;

    if (self = [super init]) {
        if (archive)
            return nil;

        options = (options & ZIP_FL_ENC_UTF_8);
        zip_int64_t idx;
        const char *file_path = NULL;

        if (filePath != nil) {
            file_path = [filePath UTF8String]; // autoreleased
            idx = zip_name_locate(archive, file_path, options);
        } else {
            idx = (int)index;
        }

        if ((idx < 0) || (zip_stat_index(archive, (zip_uint64_t)idx, options, &_file_info) < 0)) {
            if (error) {
                NSString *errorDescription;
                if (filePath) {
                    errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for “%@” in zipped file: %s", @"Cannot access file info in zipped file"),
                                        filePath, zip_strerror(archive)];
                } else {
                    errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for file %lu in zipped file: %s", @"Cannot access file info in zipped file"),
                                        (unsigned long)index, zip_strerror(archive)];
                }
                NSDictionary *errorDetail = @{NSLocalizedDescriptionKey : errorDescription};
                *error = [NSError errorWithDomain:CCArchiveFileInfoErrorDomain code:kJXCouldNotAccessZippedFileInfo userInfo:errorDetail];
            }
            return nil;
        }
    }

    return self;
}

- (CCArchiveEntry *)initFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;
{
    if (filePath == nil)
        return nil;
    else
        return [self initFileInfoWithArchive:archive
                                       index:0
                                    filePath:filePath
                                     options:options
                                       error:error];
}

+ (CCArchiveEntry *)zippedFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(CCOptionsFile)options error:(NSError **)error;
{
    return [[CCArchiveEntry alloc] initFileInfoWithArchive:archive
                                                     index:0
                                                  filePath:filePath
                                                   options:options
                                                     error:error];
}

- (CCArchiveEntry *)initFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;
{
    return [self initFileInfoWithArchive:archive
                                   index:index
                                filePath:nil
                                 options:options
                                   error:error];
}

+ (CCArchiveEntry *)zippedFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(CCOptionsFile)options error:(NSError **)error;
{
    return [[CCArchiveEntry alloc] initFileInfoWithArchive:archive
                                                     index:index
                                                  filePath:nil
                                                   options:options
                                                     error:error];
}


- (NSString *)path;
{
    if (!_path) {
        if (_file_info.valid & ZIP_STAT_NAME) {
            // FIXME: We assume the file names are UTF-8.
            _path = @(_file_info.name);
        }
    }
    return _path;
}

- (NSString *)fileName
{
    if (!_fileName) {
        if (_file_info.valid & ZIP_STAT_NAME) {
            NSString *name = [NSString stringWithUTF8String:_file_info.name];
            name = [name substringToIndex:name.length - 1];
            _fileName = [name componentsSeparatedByString:@"/"].lastObject;
        }
    }
    return _fileName;
}

- (NSUInteger)index;
{
    if (_file_info.valid & ZIP_STAT_INDEX)
        return (NSUInteger)_file_info.index;
    else
        return NSNotFound;
}

- (NSUInteger)size;
{
    if (_file_info.valid & ZIP_STAT_SIZE)
        return (NSUInteger)_file_info.size;
    else
        return NSNotFound;
}

- (NSUInteger)compressedSize;
{
    if (_file_info.valid & ZIP_STAT_COMP_SIZE)
        return (NSUInteger)_file_info.comp_size;
    else
        return NSNotFound;
}

- (NSDate *)modificationDate;
{
    if (!_modificationDate) {
        if (_file_info.valid & ZIP_STAT_MTIME) {
            _modificationDate = [NSDate dateWithTimeIntervalSince1970:_file_info.mtime];
        }
    }
    return _modificationDate;
}


- (BOOL)hasCRC;
{
    if (_file_info.valid & ZIP_STAT_CRC)
        return YES;
    else
        return NO;
}

- (uint32_t)CRC;
{
    return (uint32_t)_file_info.crc;
}


- (uint16_t)compressionMethod;
{
    if (_file_info.comp_method & ZIP_STAT_COMP_METHOD)
        return (uint16_t)_file_info.crc;
    else
        return ZIP_EM_UNKNOWN;
}

- (uint16_t)encryptionMethod;
{
    if (_file_info.encryption_method & ZIP_STAT_ENCRYPTION_METHOD)
        return (uint16_t)_file_info.crc;
    else
        return 0xffff; // Unknown
}

@end
