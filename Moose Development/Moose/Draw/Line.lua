---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by niels.
--- DateTime: 11/2/2022 7:06 AM
---
do
    LINE = {
        ClassName = "LINE",
        Points = {},
        Coords = {}
    }

    function LINE:Find(line_name)
        local self = BASE:Inherit(self, BASE:New())

        for _, layer in pairs(env.mission.drawings.layers) do
            for _, object in pairs(layer["objects"]) do
                if string.find(object["name"], line_name) then
                    if object["primitiveType"] == "Line" then
                        for index, point in UTILS.spairs(object["points"]) do
                            local p = {x = object["mapX"] + point["x"],
                                       y = object["mapY"] + point["y"] }
                            local coord = COORDINATE:NewFromVec2(p)
                            table.insert(self.Points, p)
                            table.insert(self.Coords, coord)
                        end

                        --for _, point in UTILS.spairs(self.Points) do
                        --    local p = { x = object["mapX"] + point["x"], y = object["mapY"] + point["y"] }
                        --    self:I(p)
                        --    table.insert(self.Coords, COORDINATE:NewFromVec2(p))
                        --end
                    end
                end
            end
        end

        self:I(#self.Points)
        if #self.Points == 0 then
            return nil
        end

        return self
    end

    function LINE:Coordinates()
        return self.Coords
    end

    function LINE:GetStartCoordinate()
        return self.Coords[1]
    end

    function LINE:GetEndCoordinate()
        return self.Coords[#self.Coords]
    end

    function LINE:GetStartPoint()
        return self.Points[1]
    end

    function LINE:GetEndPoint()
        return self.Points[#self.Points]
    end
end
