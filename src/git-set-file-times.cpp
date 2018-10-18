#include <iostream>
#include <exec-stream.h>
#include <regex>
#include <unordered_set>

#include <sys/types.h>
#include <utime.h>

using namespace std;

class GitSetFileTimes
{
private:
	unordered_set<string>* sFileList = nullptr;
	bool bHasQueue = false;
	bool getFileList()
	{
		if (this->sFileList != nullptr) return true;
		
		this->sFileList = new unordered_set<string>;
		
		std::string strLine;
		exec_stream_t esProc;
		esProc.start("git", "ls-files -z");
		
		while (std::getline(esProc.out(), strLine))
		{
			std::stringstream ssLine(strLine);
			std::string strFileName;
			
			while (std::getline(ssLine, strFileName, '\0'))
			{
				this->sFileList->insert(strFileName);
			}
		}
		
		this->bHasQueue = true;
		
		return true;
	}
	bool processUtime(std::string strFileName, utimbuf* utbModified) {
		if (this->sFileList->find(strFileName) != this->sFileList->end())
		{
			if (utime(strFileName.c_str(), utbModified)) {
				std::cerr
					<< "\x1b[33mWarning: an error occurred while processing \""
					<< strFileName
					<< "\".\x1b[0m\n"
				;
				return false;
			}
			
			this->sFileList->erase(strFileName);
			if (this->sFileList->empty()) {
				this->bHasQueue = false;
			}
		}
		return true;
	}
public:
	bool doUtime2GitFiles()
	{
		this->getFileList();
		
		exec_stream_t esProc;
		esProc.start("git", "--no-pager log -m -r --name-only --no-color --pretty=raw -z");
		std::string strLine;
		std::regex reCommitter("committer .*? (\\d+) (?:[\\-\\+]\\d+)");
		std::regex reCommit("\\x00\\x00commit [a-f0-9]{40}(?: \\(from [a-f0-9]{40}\\))?$");
		std::smatch matchCommitter;
		std::smatch matchCommit;
		utimbuf utbModified;
		
		while (std::getline(esProc.out(), strLine) && this->bHasQueue)
		{
			if (strLine.size() == 0) continue;
			
			bool bEndsWithNull = strLine.back() == '\0';
			
			if (
				bEndsWithNull ||
				regex_search(strLine, matchCommit, reCommit)
				)
			{
				if (!bEndsWithNull)
				{
					strLine = strLine.substr(0, matchCommit.position(0));
				}
				std::stringstream ssLine(strLine);
				std::string strFileName;
				
				while (std::getline(ssLine, strFileName, '\0'))
				{
					processUtime(strFileName, &utbModified);
				}
			}
			else if (regex_match(strLine, matchCommitter, reCommitter))
			{
				time_t timeModified = (time_t)std::stoi(matchCommitter[1]);
				utbModified.actime = timeModified;
				utbModified.modtime = timeModified;
			}
		}
		return true;
	}
	~GitSetFileTimes()
	{
		delete sFileList;
	}
};


int main() {
	GitSetFileTimes gsft;
	gsft.doUtime2GitFiles();
	return 0;
}
