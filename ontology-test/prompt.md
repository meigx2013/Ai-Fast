# 调用API接口, 解析结果集并生成分析报告

# API接口地址 
{{baseUrl}}/api/aos/contexts/{{contextId}}/snapshots?page=1&pageSize=36&status=available

## 接收基础参数
baseUrl = https://asdm-dt01.leansoftx.com
contextId = 42e8cb65-453c-4ec5-8485-617d4a5fbb53

# 解析规则
阅读 aos.json 了解结果集数据规则

# 分析报告生成规则
1. 调用API接口，从返回的结果中获取技术本体快照列表 data.items 
2. 遍历快照列表，提取数据元素： completedAt、objectCount、linkCount, 并提取出linkCount的明细数据Class、Route、Table、Mapper、Method、Module、Package、Function、Component、Interface、Dependency、Repository、ApiEndpoint
3. 根据步骤2 提取的数据生成一份快照历史数据对比的分析报告

# 要求
1. 以Markdown格式输出结果
2. 自验证，保证API接口调用成功，成功生成分析报告