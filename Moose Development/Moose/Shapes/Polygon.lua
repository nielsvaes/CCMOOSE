POLYGON = {
    ClassName = "POLYGON",
    Points = {},
    Coords = {},
    Triangles = {}
}

function POLYGON:FindOnMap(line_name)
    local self = BASE:Inherit(self, SHAPE_BASE:FindOnMap(line_name))

    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if object["name"] == line_name then
                if (object["primitiveType"] == "Line" and object["closed"] == true) or (object["polygonMode"] == "free") then
                    self.Name = object["name"]
                    for _, point in UTILS.spairs(object["points"]) do
                        local p = {x = object["mapX"] + point["x"],
                                   y = object["mapY"] + point["y"] }
                        local coord = COORDINATE:NewFromVec2(p)
                        self.Points[#self.Points + 1] = p
                        self.Coords[#self.Coords + 1] = coord
                    end
                end
            end
        end
    end

    self:I(self.Points)
    if #self.Points == 0 then
        return nil
    end

    self.CenterVec2 = self:GetCentroid()
    self.Triangles = self:Triangulate()
    return self
end

function POLYGON:FromZone(zone_name)
    for _, zone in pairs(env.mission.triggers.zones) do
        if zone["name"] == zone_name then
            return POLYGON:New(unpack(zone["verticies"] or {}))
        end
    end
end

function POLYGON:Find(shape_name)
    return _DATABASE:FindShape(shape_name)
end

function POLYGON:New(...)
    self.Points = {...}
    for _, point in spairs(self.Points) do
        table.insert(self.Coords, COORDINATE:NewFromVec2(point))
    end
    self.Triangles = self:Triangulate()
    return self
end

function POLYGON:GetCentroid()
    local function sum(t)
        local total = 0
        for _, value in pairs(t) do
            total = total + value
        end
        return total
    end

    local x_values = {}
    local y_values = {}
    local length = table.length(self.Points)

    for _, point in pairs(self.Points) do
        table.insert(x_values, point.x)
        table.insert(y_values, point.y)
    end

    local x = sum(x_values) / length
    local y = sum(y_values) / length

    return {
            ["x"] = x,
            ["y"] = y
           }
end

function POLYGON:GetCoordinates()
    return self.Coords
end

function POLYGON:GetStartCoordinate()
    return self.Coords[1]
end

function POLYGON:GetEndCoordinate()
    return self.Coords[#self.Coords]
end

function POLYGON:GetStartPoint()
    return self.Points[1]
end

function POLYGON:GetEndPoint()
    return self.Points[#self.Points]
end

function POLYGON:GetPoints()
    return self.Points
end

function POLYGON:GetBoundingBox()
    local min_x, min_y, max_x, max_y = self.Points[1].x, self.Points[1].y, self.Points[1].x, self.Points[1].y

    for i = 2, #self.Points do
        local x, y = self.Points[i].x, self.Points[i].y

        if x < min_x then
            min_x = x
        end
        if y < min_y then
            min_y = y
        end
        if x > max_x then
            max_x = x
        end
        if y > max_y then
            max_y = y
        end
    end
    return {
        {x=min_x, y=min_x}, {x=max_x, y=min_y}, {x=max_x, y=max_y}, {x=min_x, y=max_y}
    }
end

function POLYGON:Triangulate(points)
    local triangles = {}

    local function point_in_triangle(p, t)
        local function sign(p1, p2, p3)
            return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
        end

        local d1 = sign(p, t[1], t[2])
        local d2 = sign(p, t[2], t[3])
        local d3 = sign(p, t[3], t[1])

        local has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
        local has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

        return not (has_neg and has_pos)
    end

    local function divide_recursively(shape_points)
        if #shape_points == 3 then
            table.insert(triangles, shape_points) -- if there are only 3 points left, it forms a triangle
        elseif #shape_points > 3 then             -- find an ear -> a triangle with no other points inside it
            for i, p1 in ipairs(shape_points) do
                local p2 = shape_points[(i % #shape_points) + 1]
                local p3 = shape_points[(i + 1) % #shape_points + 1]
                local triangle = { p1, p2, p3 }
                local is_ear = true
                for _, point in ipairs(shape_points) do
                    if point ~= p1 and point ~= p2 and point ~= p3 and point_in_triangle(point, triangle) then
                        is_ear = false
                        break
                    end
                end
                if is_ear then
                    table.insert(triangles, triangle)
                    local remaining_points = {}
                    for j, point in ipairs(shape_points) do
                        if point ~= p2 then
                            table.insert(remaining_points, point)
                        end
                    end
                    divide_recursively(remaining_points)
                    break
                end
            end
        end
    end

    divide_recursively(points)
    return triangles
end

function POLYGON:GetRandomVec2()
    return UTILS.RandomPointInTriangle(self.Triangles[math.random(0, #self.Triangles)])
end

function POLYGON:ContainsPoint(point, polygon_points)
    local x = point.x
    local y = point.y

    polygon_points = polygon_points or self.Points

    local counter = 0
    local num_points = #polygon_points
    for current_index = 1, num_points do
        local next_index = (current_index % num_points) + 1
        local current_x, current_y = polygon_points[current_index].x, polygon_points[current_index].y
        local next_x, next_y = polygon_points[next_index].x, polygon_points[next_index].y
        if ((current_y > y) ~= (next_y > y)) and (x < (next_x - current_x) * (y - current_y) / (next_y - current_y) + current_x) then
            counter = counter + 1
        end
    end
    return counter % 2 == 1
end
